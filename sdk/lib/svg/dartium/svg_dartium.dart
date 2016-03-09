/**
 * Scalable Vector Graphics:
 * Two-dimensional vector graphics with support for events and animation.
 *
 * For details about the features and syntax of SVG, a W3C standard,
 * refer to the
 * [Scalable Vector Graphics Specification](http://www.w3.org/TR/SVG/).
 */
library dart.dom.svg;

import 'dart:async';
import 'dart:collection';
import 'dart:_internal';
import 'dart:html';
import 'dart:html_common';
import 'dart:nativewrappers';
import 'dart:_blink' as _blink;
import 'dart:js' as js;
// DO NOT EDIT
// Auto-generated dart:svg library.





// FIXME: Can we make this private?
@Deprecated("Internal Use Only")
final svgBlinkMap = {
  'SVGAElement': () => AElement,
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
  'SVGForeignObjectElement': () => ForeignObjectElement,
  'SVGGElement': () => GElement,
  'SVGGeometryElement': () => GeometryElement,
  'SVGGradientElement': () => _GradientElement,
  'SVGGraphicsElement': () => GraphicsElement,
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
  'SVGViewElement': () => ViewElement,
  'SVGViewSpec': () => ViewSpec,
  'SVGZoomAndPan': () => ZoomAndPan,
  'SVGZoomEvent': () => ZoomEvent,

};

// FIXME: Can we make this private?
@Deprecated("Internal Use Only")
final svgBlinkFunctionMap = {
  'SVGAElement': () => AElement.internalCreateAElement,
  'SVGAngle': () => Angle.internalCreateAngle,
  'SVGAnimateElement': () => AnimateElement.internalCreateAnimateElement,
  'SVGAnimateMotionElement': () => AnimateMotionElement.internalCreateAnimateMotionElement,
  'SVGAnimateTransformElement': () => AnimateTransformElement.internalCreateAnimateTransformElement,
  'SVGAnimatedAngle': () => AnimatedAngle.internalCreateAnimatedAngle,
  'SVGAnimatedBoolean': () => AnimatedBoolean.internalCreateAnimatedBoolean,
  'SVGAnimatedEnumeration': () => AnimatedEnumeration.internalCreateAnimatedEnumeration,
  'SVGAnimatedInteger': () => AnimatedInteger.internalCreateAnimatedInteger,
  'SVGAnimatedLength': () => AnimatedLength.internalCreateAnimatedLength,
  'SVGAnimatedLengthList': () => AnimatedLengthList.internalCreateAnimatedLengthList,
  'SVGAnimatedNumber': () => AnimatedNumber.internalCreateAnimatedNumber,
  'SVGAnimatedNumberList': () => AnimatedNumberList.internalCreateAnimatedNumberList,
  'SVGAnimatedPreserveAspectRatio': () => AnimatedPreserveAspectRatio.internalCreateAnimatedPreserveAspectRatio,
  'SVGAnimatedRect': () => AnimatedRect.internalCreateAnimatedRect,
  'SVGAnimatedString': () => AnimatedString.internalCreateAnimatedString,
  'SVGAnimatedTransformList': () => AnimatedTransformList.internalCreateAnimatedTransformList,
  'SVGAnimationElement': () => AnimationElement.internalCreateAnimationElement,
  'SVGCircleElement': () => CircleElement.internalCreateCircleElement,
  'SVGClipPathElement': () => ClipPathElement.internalCreateClipPathElement,
  'SVGComponentTransferFunctionElement': () => _SVGComponentTransferFunctionElement.internalCreate_SVGComponentTransferFunctionElement,
  'SVGCursorElement': () => _SVGCursorElement.internalCreate_SVGCursorElement,
  'SVGDefsElement': () => DefsElement.internalCreateDefsElement,
  'SVGDescElement': () => DescElement.internalCreateDescElement,
  'SVGDiscardElement': () => DiscardElement.internalCreateDiscardElement,
  'SVGElement': () => SvgElement.internalCreateSvgElement,
  'SVGEllipseElement': () => EllipseElement.internalCreateEllipseElement,
  'SVGFEBlendElement': () => FEBlendElement.internalCreateFEBlendElement,
  'SVGFEColorMatrixElement': () => FEColorMatrixElement.internalCreateFEColorMatrixElement,
  'SVGFEComponentTransferElement': () => FEComponentTransferElement.internalCreateFEComponentTransferElement,
  'SVGFECompositeElement': () => FECompositeElement.internalCreateFECompositeElement,
  'SVGFEConvolveMatrixElement': () => FEConvolveMatrixElement.internalCreateFEConvolveMatrixElement,
  'SVGFEDiffuseLightingElement': () => FEDiffuseLightingElement.internalCreateFEDiffuseLightingElement,
  'SVGFEDisplacementMapElement': () => FEDisplacementMapElement.internalCreateFEDisplacementMapElement,
  'SVGFEDistantLightElement': () => FEDistantLightElement.internalCreateFEDistantLightElement,
  'SVGFEDropShadowElement': () => _SVGFEDropShadowElement.internalCreate_SVGFEDropShadowElement,
  'SVGFEFloodElement': () => FEFloodElement.internalCreateFEFloodElement,
  'SVGFEFuncAElement': () => FEFuncAElement.internalCreateFEFuncAElement,
  'SVGFEFuncBElement': () => FEFuncBElement.internalCreateFEFuncBElement,
  'SVGFEFuncGElement': () => FEFuncGElement.internalCreateFEFuncGElement,
  'SVGFEFuncRElement': () => FEFuncRElement.internalCreateFEFuncRElement,
  'SVGFEGaussianBlurElement': () => FEGaussianBlurElement.internalCreateFEGaussianBlurElement,
  'SVGFEImageElement': () => FEImageElement.internalCreateFEImageElement,
  'SVGFEMergeElement': () => FEMergeElement.internalCreateFEMergeElement,
  'SVGFEMergeNodeElement': () => FEMergeNodeElement.internalCreateFEMergeNodeElement,
  'SVGFEMorphologyElement': () => FEMorphologyElement.internalCreateFEMorphologyElement,
  'SVGFEOffsetElement': () => FEOffsetElement.internalCreateFEOffsetElement,
  'SVGFEPointLightElement': () => FEPointLightElement.internalCreateFEPointLightElement,
  'SVGFESpecularLightingElement': () => FESpecularLightingElement.internalCreateFESpecularLightingElement,
  'SVGFESpotLightElement': () => FESpotLightElement.internalCreateFESpotLightElement,
  'SVGFETileElement': () => FETileElement.internalCreateFETileElement,
  'SVGFETurbulenceElement': () => FETurbulenceElement.internalCreateFETurbulenceElement,
  'SVGFilterElement': () => FilterElement.internalCreateFilterElement,
  'SVGForeignObjectElement': () => ForeignObjectElement.internalCreateForeignObjectElement,
  'SVGGElement': () => GElement.internalCreateGElement,
  'SVGGeometryElement': () => GeometryElement.internalCreateGeometryElement,
  'SVGGradientElement': () => _GradientElement.internalCreate_GradientElement,
  'SVGGraphicsElement': () => GraphicsElement.internalCreateGraphicsElement,
  'SVGImageElement': () => ImageElement.internalCreateImageElement,
  'SVGLength': () => Length.internalCreateLength,
  'SVGLengthList': () => LengthList.internalCreateLengthList,
  'SVGLineElement': () => LineElement.internalCreateLineElement,
  'SVGLinearGradientElement': () => LinearGradientElement.internalCreateLinearGradientElement,
  'SVGMPathElement': () => _SVGMPathElement.internalCreate_SVGMPathElement,
  'SVGMarkerElement': () => MarkerElement.internalCreateMarkerElement,
  'SVGMaskElement': () => MaskElement.internalCreateMaskElement,
  'SVGMatrix': () => Matrix.internalCreateMatrix,
  'SVGMetadataElement': () => MetadataElement.internalCreateMetadataElement,
  'SVGNumber': () => Number.internalCreateNumber,
  'SVGNumberList': () => NumberList.internalCreateNumberList,
  'SVGPathElement': () => PathElement.internalCreatePathElement,
  'SVGPathSeg': () => PathSeg.internalCreatePathSeg,
  'SVGPathSegArcAbs': () => PathSegArcAbs.internalCreatePathSegArcAbs,
  'SVGPathSegArcRel': () => PathSegArcRel.internalCreatePathSegArcRel,
  'SVGPathSegClosePath': () => PathSegClosePath.internalCreatePathSegClosePath,
  'SVGPathSegCurvetoCubicAbs': () => PathSegCurvetoCubicAbs.internalCreatePathSegCurvetoCubicAbs,
  'SVGPathSegCurvetoCubicRel': () => PathSegCurvetoCubicRel.internalCreatePathSegCurvetoCubicRel,
  'SVGPathSegCurvetoCubicSmoothAbs': () => PathSegCurvetoCubicSmoothAbs.internalCreatePathSegCurvetoCubicSmoothAbs,
  'SVGPathSegCurvetoCubicSmoothRel': () => PathSegCurvetoCubicSmoothRel.internalCreatePathSegCurvetoCubicSmoothRel,
  'SVGPathSegCurvetoQuadraticAbs': () => PathSegCurvetoQuadraticAbs.internalCreatePathSegCurvetoQuadraticAbs,
  'SVGPathSegCurvetoQuadraticRel': () => PathSegCurvetoQuadraticRel.internalCreatePathSegCurvetoQuadraticRel,
  'SVGPathSegCurvetoQuadraticSmoothAbs': () => PathSegCurvetoQuadraticSmoothAbs.internalCreatePathSegCurvetoQuadraticSmoothAbs,
  'SVGPathSegCurvetoQuadraticSmoothRel': () => PathSegCurvetoQuadraticSmoothRel.internalCreatePathSegCurvetoQuadraticSmoothRel,
  'SVGPathSegLinetoAbs': () => PathSegLinetoAbs.internalCreatePathSegLinetoAbs,
  'SVGPathSegLinetoHorizontalAbs': () => PathSegLinetoHorizontalAbs.internalCreatePathSegLinetoHorizontalAbs,
  'SVGPathSegLinetoHorizontalRel': () => PathSegLinetoHorizontalRel.internalCreatePathSegLinetoHorizontalRel,
  'SVGPathSegLinetoRel': () => PathSegLinetoRel.internalCreatePathSegLinetoRel,
  'SVGPathSegLinetoVerticalAbs': () => PathSegLinetoVerticalAbs.internalCreatePathSegLinetoVerticalAbs,
  'SVGPathSegLinetoVerticalRel': () => PathSegLinetoVerticalRel.internalCreatePathSegLinetoVerticalRel,
  'SVGPathSegList': () => PathSegList.internalCreatePathSegList,
  'SVGPathSegMovetoAbs': () => PathSegMovetoAbs.internalCreatePathSegMovetoAbs,
  'SVGPathSegMovetoRel': () => PathSegMovetoRel.internalCreatePathSegMovetoRel,
  'SVGPatternElement': () => PatternElement.internalCreatePatternElement,
  'SVGPoint': () => Point.internalCreatePoint,
  'SVGPointList': () => PointList.internalCreatePointList,
  'SVGPolygonElement': () => PolygonElement.internalCreatePolygonElement,
  'SVGPolylineElement': () => PolylineElement.internalCreatePolylineElement,
  'SVGPreserveAspectRatio': () => PreserveAspectRatio.internalCreatePreserveAspectRatio,
  'SVGRadialGradientElement': () => RadialGradientElement.internalCreateRadialGradientElement,
  'SVGRect': () => Rect.internalCreateRect,
  'SVGRectElement': () => RectElement.internalCreateRectElement,
  'SVGSVGElement': () => SvgSvgElement.internalCreateSvgSvgElement,
  'SVGScriptElement': () => ScriptElement.internalCreateScriptElement,
  'SVGSetElement': () => SetElement.internalCreateSetElement,
  'SVGStopElement': () => StopElement.internalCreateStopElement,
  'SVGStringList': () => StringList.internalCreateStringList,
  'SVGStyleElement': () => StyleElement.internalCreateStyleElement,
  'SVGSwitchElement': () => SwitchElement.internalCreateSwitchElement,
  'SVGSymbolElement': () => SymbolElement.internalCreateSymbolElement,
  'SVGTSpanElement': () => TSpanElement.internalCreateTSpanElement,
  'SVGTextContentElement': () => TextContentElement.internalCreateTextContentElement,
  'SVGTextElement': () => TextElement.internalCreateTextElement,
  'SVGTextPathElement': () => TextPathElement.internalCreateTextPathElement,
  'SVGTextPositioningElement': () => TextPositioningElement.internalCreateTextPositioningElement,
  'SVGTitleElement': () => TitleElement.internalCreateTitleElement,
  'SVGTransform': () => Transform.internalCreateTransform,
  'SVGTransformList': () => TransformList.internalCreateTransformList,
  'SVGUnitTypes': () => UnitTypes.internalCreateUnitTypes,
  'SVGUseElement': () => UseElement.internalCreateUseElement,
  'SVGViewElement': () => ViewElement.internalCreateViewElement,
  'SVGViewSpec': () => ViewSpec.internalCreateViewSpec,
  'SVGZoomEvent': () => ZoomEvent.internalCreateZoomEvent,

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


  @Deprecated("Internal Use Only")
  static AElement internalCreateAElement() {
    return new AElement._internalWrap();
  }

  external factory AElement._internalWrap();

  @Deprecated("Internal Use Only")
  AElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  AElement.created() : super.created();

  @DomName('SVGAElement.target')
  @DocsEditable()
  AnimatedString get target => wrap_jso(_blink.BlinkSVGAElement.instance.target_Getter_(unwrap_jso(this)));
  
  @DomName('SVGAElement.href')
  @DocsEditable()
  AnimatedString get href => wrap_jso(_blink.BlinkSVGAElement.instance.href_Getter_(unwrap_jso(this)));
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAngle')
@Unstable()
class Angle extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory Angle._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static Angle internalCreateAngle() {
    return new Angle._internalWrap();
  }

  factory Angle._internalWrap() {
    return new Angle.internal_();
  }

  @Deprecated("Internal Use Only")
  Angle.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

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
  int get unitType => _blink.BlinkSVGAngle.instance.unitType_Getter_(unwrap_jso(this));
  
  @DomName('SVGAngle.value')
  @DocsEditable()
  num get value => _blink.BlinkSVGAngle.instance.value_Getter_(unwrap_jso(this));
  
  @DomName('SVGAngle.value')
  @DocsEditable()
  set value(num value) => _blink.BlinkSVGAngle.instance.value_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGAngle.valueAsString')
  @DocsEditable()
  String get valueAsString => _blink.BlinkSVGAngle.instance.valueAsString_Getter_(unwrap_jso(this));
  
  @DomName('SVGAngle.valueAsString')
  @DocsEditable()
  set valueAsString(String value) => _blink.BlinkSVGAngle.instance.valueAsString_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGAngle.valueInSpecifiedUnits')
  @DocsEditable()
  num get valueInSpecifiedUnits => _blink.BlinkSVGAngle.instance.valueInSpecifiedUnits_Getter_(unwrap_jso(this));
  
  @DomName('SVGAngle.valueInSpecifiedUnits')
  @DocsEditable()
  set valueInSpecifiedUnits(num value) => _blink.BlinkSVGAngle.instance.valueInSpecifiedUnits_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGAngle.convertToSpecifiedUnits')
  @DocsEditable()
  void convertToSpecifiedUnits(int unitType) => _blink.BlinkSVGAngle.instance.convertToSpecifiedUnits_Callback_1_(unwrap_jso(this), unitType);
  
  @DomName('SVGAngle.newValueSpecifiedUnits')
  @DocsEditable()
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) => _blink.BlinkSVGAngle.instance.newValueSpecifiedUnits_Callback_2_(unwrap_jso(this), unitType, valueInSpecifiedUnits);
  
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


  @Deprecated("Internal Use Only")
  static AnimateElement internalCreateAnimateElement() {
    return new AnimateElement._internalWrap();
  }

  external factory AnimateElement._internalWrap();

  @Deprecated("Internal Use Only")
  AnimateElement.internal_() : super.internal_();

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


  @Deprecated("Internal Use Only")
  static AnimateMotionElement internalCreateAnimateMotionElement() {
    return new AnimateMotionElement._internalWrap();
  }

  external factory AnimateMotionElement._internalWrap();

  @Deprecated("Internal Use Only")
  AnimateMotionElement.internal_() : super.internal_();

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


  @Deprecated("Internal Use Only")
  static AnimateTransformElement internalCreateAnimateTransformElement() {
    return new AnimateTransformElement._internalWrap();
  }

  external factory AnimateTransformElement._internalWrap();

  @Deprecated("Internal Use Only")
  AnimateTransformElement.internal_() : super.internal_();

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
class AnimatedAngle extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AnimatedAngle._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static AnimatedAngle internalCreateAnimatedAngle() {
    return new AnimatedAngle._internalWrap();
  }

  factory AnimatedAngle._internalWrap() {
    return new AnimatedAngle.internal_();
  }

  @Deprecated("Internal Use Only")
  AnimatedAngle.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SVGAnimatedAngle.animVal')
  @DocsEditable()
  Angle get animVal => wrap_jso(_blink.BlinkSVGAnimatedAngle.instance.animVal_Getter_(unwrap_jso(this)));
  
  @DomName('SVGAnimatedAngle.baseVal')
  @DocsEditable()
  Angle get baseVal => wrap_jso(_blink.BlinkSVGAnimatedAngle.instance.baseVal_Getter_(unwrap_jso(this)));
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedBoolean')
@Unstable()
class AnimatedBoolean extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AnimatedBoolean._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static AnimatedBoolean internalCreateAnimatedBoolean() {
    return new AnimatedBoolean._internalWrap();
  }

  factory AnimatedBoolean._internalWrap() {
    return new AnimatedBoolean.internal_();
  }

  @Deprecated("Internal Use Only")
  AnimatedBoolean.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SVGAnimatedBoolean.animVal')
  @DocsEditable()
  bool get animVal => _blink.BlinkSVGAnimatedBoolean.instance.animVal_Getter_(unwrap_jso(this));
  
  @DomName('SVGAnimatedBoolean.baseVal')
  @DocsEditable()
  bool get baseVal => _blink.BlinkSVGAnimatedBoolean.instance.baseVal_Getter_(unwrap_jso(this));
  
  @DomName('SVGAnimatedBoolean.baseVal')
  @DocsEditable()
  set baseVal(bool value) => _blink.BlinkSVGAnimatedBoolean.instance.baseVal_Setter_(unwrap_jso(this), value);
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedEnumeration')
@Unstable()
class AnimatedEnumeration extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AnimatedEnumeration._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static AnimatedEnumeration internalCreateAnimatedEnumeration() {
    return new AnimatedEnumeration._internalWrap();
  }

  factory AnimatedEnumeration._internalWrap() {
    return new AnimatedEnumeration.internal_();
  }

  @Deprecated("Internal Use Only")
  AnimatedEnumeration.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SVGAnimatedEnumeration.animVal')
  @DocsEditable()
  int get animVal => _blink.BlinkSVGAnimatedEnumeration.instance.animVal_Getter_(unwrap_jso(this));
  
  @DomName('SVGAnimatedEnumeration.baseVal')
  @DocsEditable()
  int get baseVal => _blink.BlinkSVGAnimatedEnumeration.instance.baseVal_Getter_(unwrap_jso(this));
  
  @DomName('SVGAnimatedEnumeration.baseVal')
  @DocsEditable()
  set baseVal(int value) => _blink.BlinkSVGAnimatedEnumeration.instance.baseVal_Setter_(unwrap_jso(this), value);
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedInteger')
@Unstable()
class AnimatedInteger extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AnimatedInteger._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static AnimatedInteger internalCreateAnimatedInteger() {
    return new AnimatedInteger._internalWrap();
  }

  factory AnimatedInteger._internalWrap() {
    return new AnimatedInteger.internal_();
  }

  @Deprecated("Internal Use Only")
  AnimatedInteger.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SVGAnimatedInteger.animVal')
  @DocsEditable()
  int get animVal => _blink.BlinkSVGAnimatedInteger.instance.animVal_Getter_(unwrap_jso(this));
  
  @DomName('SVGAnimatedInteger.baseVal')
  @DocsEditable()
  int get baseVal => _blink.BlinkSVGAnimatedInteger.instance.baseVal_Getter_(unwrap_jso(this));
  
  @DomName('SVGAnimatedInteger.baseVal')
  @DocsEditable()
  set baseVal(int value) => _blink.BlinkSVGAnimatedInteger.instance.baseVal_Setter_(unwrap_jso(this), value);
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedLength')
@Unstable()
class AnimatedLength extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AnimatedLength._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static AnimatedLength internalCreateAnimatedLength() {
    return new AnimatedLength._internalWrap();
  }

  factory AnimatedLength._internalWrap() {
    return new AnimatedLength.internal_();
  }

  @Deprecated("Internal Use Only")
  AnimatedLength.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SVGAnimatedLength.animVal')
  @DocsEditable()
  Length get animVal => wrap_jso(_blink.BlinkSVGAnimatedLength.instance.animVal_Getter_(unwrap_jso(this)));
  
  @DomName('SVGAnimatedLength.baseVal')
  @DocsEditable()
  Length get baseVal => wrap_jso(_blink.BlinkSVGAnimatedLength.instance.baseVal_Getter_(unwrap_jso(this)));
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedLengthList')
@Unstable()
class AnimatedLengthList extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AnimatedLengthList._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static AnimatedLengthList internalCreateAnimatedLengthList() {
    return new AnimatedLengthList._internalWrap();
  }

  factory AnimatedLengthList._internalWrap() {
    return new AnimatedLengthList.internal_();
  }

  @Deprecated("Internal Use Only")
  AnimatedLengthList.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SVGAnimatedLengthList.animVal')
  @DocsEditable()
  LengthList get animVal => wrap_jso(_blink.BlinkSVGAnimatedLengthList.instance.animVal_Getter_(unwrap_jso(this)));
  
  @DomName('SVGAnimatedLengthList.baseVal')
  @DocsEditable()
  LengthList get baseVal => wrap_jso(_blink.BlinkSVGAnimatedLengthList.instance.baseVal_Getter_(unwrap_jso(this)));
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedNumber')
@Unstable()
class AnimatedNumber extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AnimatedNumber._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static AnimatedNumber internalCreateAnimatedNumber() {
    return new AnimatedNumber._internalWrap();
  }

  factory AnimatedNumber._internalWrap() {
    return new AnimatedNumber.internal_();
  }

  @Deprecated("Internal Use Only")
  AnimatedNumber.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SVGAnimatedNumber.animVal')
  @DocsEditable()
  num get animVal => _blink.BlinkSVGAnimatedNumber.instance.animVal_Getter_(unwrap_jso(this));
  
  @DomName('SVGAnimatedNumber.baseVal')
  @DocsEditable()
  num get baseVal => _blink.BlinkSVGAnimatedNumber.instance.baseVal_Getter_(unwrap_jso(this));
  
  @DomName('SVGAnimatedNumber.baseVal')
  @DocsEditable()
  set baseVal(num value) => _blink.BlinkSVGAnimatedNumber.instance.baseVal_Setter_(unwrap_jso(this), value);
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedNumberList')
@Unstable()
class AnimatedNumberList extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AnimatedNumberList._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static AnimatedNumberList internalCreateAnimatedNumberList() {
    return new AnimatedNumberList._internalWrap();
  }

  factory AnimatedNumberList._internalWrap() {
    return new AnimatedNumberList.internal_();
  }

  @Deprecated("Internal Use Only")
  AnimatedNumberList.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SVGAnimatedNumberList.animVal')
  @DocsEditable()
  NumberList get animVal => wrap_jso(_blink.BlinkSVGAnimatedNumberList.instance.animVal_Getter_(unwrap_jso(this)));
  
  @DomName('SVGAnimatedNumberList.baseVal')
  @DocsEditable()
  NumberList get baseVal => wrap_jso(_blink.BlinkSVGAnimatedNumberList.instance.baseVal_Getter_(unwrap_jso(this)));
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedPreserveAspectRatio')
@Unstable()
class AnimatedPreserveAspectRatio extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AnimatedPreserveAspectRatio._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static AnimatedPreserveAspectRatio internalCreateAnimatedPreserveAspectRatio() {
    return new AnimatedPreserveAspectRatio._internalWrap();
  }

  factory AnimatedPreserveAspectRatio._internalWrap() {
    return new AnimatedPreserveAspectRatio.internal_();
  }

  @Deprecated("Internal Use Only")
  AnimatedPreserveAspectRatio.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SVGAnimatedPreserveAspectRatio.animVal')
  @DocsEditable()
  PreserveAspectRatio get animVal => wrap_jso(_blink.BlinkSVGAnimatedPreserveAspectRatio.instance.animVal_Getter_(unwrap_jso(this)));
  
  @DomName('SVGAnimatedPreserveAspectRatio.baseVal')
  @DocsEditable()
  PreserveAspectRatio get baseVal => wrap_jso(_blink.BlinkSVGAnimatedPreserveAspectRatio.instance.baseVal_Getter_(unwrap_jso(this)));
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedRect')
@Unstable()
class AnimatedRect extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AnimatedRect._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static AnimatedRect internalCreateAnimatedRect() {
    return new AnimatedRect._internalWrap();
  }

  factory AnimatedRect._internalWrap() {
    return new AnimatedRect.internal_();
  }

  @Deprecated("Internal Use Only")
  AnimatedRect.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SVGAnimatedRect.animVal')
  @DocsEditable()
  Rect get animVal => wrap_jso(_blink.BlinkSVGAnimatedRect.instance.animVal_Getter_(unwrap_jso(this)));
  
  @DomName('SVGAnimatedRect.baseVal')
  @DocsEditable()
  Rect get baseVal => wrap_jso(_blink.BlinkSVGAnimatedRect.instance.baseVal_Getter_(unwrap_jso(this)));
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedString')
@Unstable()
class AnimatedString extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AnimatedString._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static AnimatedString internalCreateAnimatedString() {
    return new AnimatedString._internalWrap();
  }

  factory AnimatedString._internalWrap() {
    return new AnimatedString.internal_();
  }

  @Deprecated("Internal Use Only")
  AnimatedString.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SVGAnimatedString.animVal')
  @DocsEditable()
  String get animVal => _blink.BlinkSVGAnimatedString.instance.animVal_Getter_(unwrap_jso(this));
  
  @DomName('SVGAnimatedString.baseVal')
  @DocsEditable()
  String get baseVal => _blink.BlinkSVGAnimatedString.instance.baseVal_Getter_(unwrap_jso(this));
  
  @DomName('SVGAnimatedString.baseVal')
  @DocsEditable()
  set baseVal(String value) => _blink.BlinkSVGAnimatedString.instance.baseVal_Setter_(unwrap_jso(this), value);
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedTransformList')
@Unstable()
class AnimatedTransformList extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AnimatedTransformList._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static AnimatedTransformList internalCreateAnimatedTransformList() {
    return new AnimatedTransformList._internalWrap();
  }

  factory AnimatedTransformList._internalWrap() {
    return new AnimatedTransformList.internal_();
  }

  @Deprecated("Internal Use Only")
  AnimatedTransformList.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SVGAnimatedTransformList.animVal')
  @DocsEditable()
  TransformList get animVal => wrap_jso(_blink.BlinkSVGAnimatedTransformList.instance.animVal_Getter_(unwrap_jso(this)));
  
  @DomName('SVGAnimatedTransformList.baseVal')
  @DocsEditable()
  TransformList get baseVal => wrap_jso(_blink.BlinkSVGAnimatedTransformList.instance.baseVal_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static AnimationElement internalCreateAnimationElement() {
    return new AnimationElement._internalWrap();
  }

  external factory AnimationElement._internalWrap();

  @Deprecated("Internal Use Only")
  AnimationElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  AnimationElement.created() : super.created();

  @DomName('SVGAnimationElement.targetElement')
  @DocsEditable()
  SvgElement get targetElement => wrap_jso(_blink.BlinkSVGAnimationElement.instance.targetElement_Getter_(unwrap_jso(this)));
  
  @DomName('SVGAnimationElement.beginElement')
  @DocsEditable()
  void beginElement() => _blink.BlinkSVGAnimationElement.instance.beginElement_Callback_0_(unwrap_jso(this));
  
  @DomName('SVGAnimationElement.beginElementAt')
  @DocsEditable()
  void beginElementAt(num offset) => _blink.BlinkSVGAnimationElement.instance.beginElementAt_Callback_1_(unwrap_jso(this), offset);
  
  @DomName('SVGAnimationElement.endElement')
  @DocsEditable()
  void endElement() => _blink.BlinkSVGAnimationElement.instance.endElement_Callback_0_(unwrap_jso(this));
  
  @DomName('SVGAnimationElement.endElementAt')
  @DocsEditable()
  void endElementAt(num offset) => _blink.BlinkSVGAnimationElement.instance.endElementAt_Callback_1_(unwrap_jso(this), offset);
  
  @DomName('SVGAnimationElement.getCurrentTime')
  @DocsEditable()
  num getCurrentTime() => _blink.BlinkSVGAnimationElement.instance.getCurrentTime_Callback_0_(unwrap_jso(this));
  
  @DomName('SVGAnimationElement.getSimpleDuration')
  @DocsEditable()
  num getSimpleDuration() => _blink.BlinkSVGAnimationElement.instance.getSimpleDuration_Callback_0_(unwrap_jso(this));
  
  @DomName('SVGAnimationElement.getStartTime')
  @DocsEditable()
  num getStartTime() => _blink.BlinkSVGAnimationElement.instance.getStartTime_Callback_0_(unwrap_jso(this));
  
  @DomName('SVGAnimationElement.requiredExtensions')
  @DocsEditable()
  StringList get requiredExtensions => wrap_jso(_blink.BlinkSVGAnimationElement.instance.requiredExtensions_Getter_(unwrap_jso(this)));
  
  @DomName('SVGAnimationElement.requiredFeatures')
  @DocsEditable()
  StringList get requiredFeatures => wrap_jso(_blink.BlinkSVGAnimationElement.instance.requiredFeatures_Getter_(unwrap_jso(this)));
  
  @DomName('SVGAnimationElement.systemLanguage')
  @DocsEditable()
  StringList get systemLanguage => wrap_jso(_blink.BlinkSVGAnimationElement.instance.systemLanguage_Getter_(unwrap_jso(this)));
  
  @DomName('SVGAnimationElement.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) => _blink.BlinkSVGAnimationElement.instance.hasExtension_Callback_1_(unwrap_jso(this), extension);
  
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


  @Deprecated("Internal Use Only")
  static CircleElement internalCreateCircleElement() {
    return new CircleElement._internalWrap();
  }

  external factory CircleElement._internalWrap();

  @Deprecated("Internal Use Only")
  CircleElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  CircleElement.created() : super.created();

  @DomName('SVGCircleElement.cx')
  @DocsEditable()
  AnimatedLength get cx => wrap_jso(_blink.BlinkSVGCircleElement.instance.cx_Getter_(unwrap_jso(this)));
  
  @DomName('SVGCircleElement.cy')
  @DocsEditable()
  AnimatedLength get cy => wrap_jso(_blink.BlinkSVGCircleElement.instance.cy_Getter_(unwrap_jso(this)));
  
  @DomName('SVGCircleElement.r')
  @DocsEditable()
  AnimatedLength get r => wrap_jso(_blink.BlinkSVGCircleElement.instance.r_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static ClipPathElement internalCreateClipPathElement() {
    return new ClipPathElement._internalWrap();
  }

  external factory ClipPathElement._internalWrap();

  @Deprecated("Internal Use Only")
  ClipPathElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  ClipPathElement.created() : super.created();

  @DomName('SVGClipPathElement.clipPathUnits')
  @DocsEditable()
  AnimatedEnumeration get clipPathUnits => wrap_jso(_blink.BlinkSVGClipPathElement.instance.clipPathUnits_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static DefsElement internalCreateDefsElement() {
    return new DefsElement._internalWrap();
  }

  external factory DefsElement._internalWrap();

  @Deprecated("Internal Use Only")
  DefsElement.internal_() : super.internal_();

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


  @Deprecated("Internal Use Only")
  static DescElement internalCreateDescElement() {
    return new DescElement._internalWrap();
  }

  external factory DescElement._internalWrap();

  @Deprecated("Internal Use Only")
  DescElement.internal_() : super.internal_();

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


  @Deprecated("Internal Use Only")
  static DiscardElement internalCreateDiscardElement() {
    return new DiscardElement._internalWrap();
  }

  external factory DiscardElement._internalWrap();

  @Deprecated("Internal Use Only")
  DiscardElement.internal_() : super.internal_();

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
@DomName('SVGEllipseElement')
@Unstable()
class EllipseElement extends GeometryElement {
  // To suppress missing implicit constructor warnings.
  factory EllipseElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGEllipseElement.SVGEllipseElement')
  @DocsEditable()
  factory EllipseElement() => _SvgElementFactoryProvider.createSvgElement_tag("ellipse");


  @Deprecated("Internal Use Only")
  static EllipseElement internalCreateEllipseElement() {
    return new EllipseElement._internalWrap();
  }

  external factory EllipseElement._internalWrap();

  @Deprecated("Internal Use Only")
  EllipseElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  EllipseElement.created() : super.created();

  @DomName('SVGEllipseElement.cx')
  @DocsEditable()
  AnimatedLength get cx => wrap_jso(_blink.BlinkSVGEllipseElement.instance.cx_Getter_(unwrap_jso(this)));
  
  @DomName('SVGEllipseElement.cy')
  @DocsEditable()
  AnimatedLength get cy => wrap_jso(_blink.BlinkSVGEllipseElement.instance.cy_Getter_(unwrap_jso(this)));
  
  @DomName('SVGEllipseElement.rx')
  @DocsEditable()
  AnimatedLength get rx => wrap_jso(_blink.BlinkSVGEllipseElement.instance.rx_Getter_(unwrap_jso(this)));
  
  @DomName('SVGEllipseElement.ry')
  @DocsEditable()
  AnimatedLength get ry => wrap_jso(_blink.BlinkSVGEllipseElement.instance.ry_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static FEBlendElement internalCreateFEBlendElement() {
    return new FEBlendElement._internalWrap();
  }

  external factory FEBlendElement._internalWrap();

  @Deprecated("Internal Use Only")
  FEBlendElement.internal_() : super.internal_();

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
  AnimatedString get in1 => wrap_jso(_blink.BlinkSVGFEBlendElement.instance.in1_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEBlendElement.in2')
  @DocsEditable()
  AnimatedString get in2 => wrap_jso(_blink.BlinkSVGFEBlendElement.instance.in2_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEBlendElement.mode')
  @DocsEditable()
  AnimatedEnumeration get mode => wrap_jso(_blink.BlinkSVGFEBlendElement.instance.mode_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEBlendElement.height')
  @DocsEditable()
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGFEBlendElement.instance.height_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEBlendElement.result')
  @DocsEditable()
  AnimatedString get result => wrap_jso(_blink.BlinkSVGFEBlendElement.instance.result_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEBlendElement.width')
  @DocsEditable()
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGFEBlendElement.instance.width_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEBlendElement.x')
  @DocsEditable()
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGFEBlendElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEBlendElement.y')
  @DocsEditable()
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGFEBlendElement.instance.y_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static FEColorMatrixElement internalCreateFEColorMatrixElement() {
    return new FEColorMatrixElement._internalWrap();
  }

  external factory FEColorMatrixElement._internalWrap();

  @Deprecated("Internal Use Only")
  FEColorMatrixElement.internal_() : super.internal_();

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
  AnimatedString get in1 => wrap_jso(_blink.BlinkSVGFEColorMatrixElement.instance.in1_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEColorMatrixElement.type')
  @DocsEditable()
  AnimatedEnumeration get type => wrap_jso(_blink.BlinkSVGFEColorMatrixElement.instance.type_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEColorMatrixElement.values')
  @DocsEditable()
  AnimatedNumberList get values => wrap_jso(_blink.BlinkSVGFEColorMatrixElement.instance.values_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEColorMatrixElement.height')
  @DocsEditable()
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGFEColorMatrixElement.instance.height_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEColorMatrixElement.result')
  @DocsEditable()
  AnimatedString get result => wrap_jso(_blink.BlinkSVGFEColorMatrixElement.instance.result_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEColorMatrixElement.width')
  @DocsEditable()
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGFEColorMatrixElement.instance.width_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEColorMatrixElement.x')
  @DocsEditable()
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGFEColorMatrixElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEColorMatrixElement.y')
  @DocsEditable()
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGFEColorMatrixElement.instance.y_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static FEComponentTransferElement internalCreateFEComponentTransferElement() {
    return new FEComponentTransferElement._internalWrap();
  }

  external factory FEComponentTransferElement._internalWrap();

  @Deprecated("Internal Use Only")
  FEComponentTransferElement.internal_() : super.internal_();

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
  AnimatedString get in1 => wrap_jso(_blink.BlinkSVGFEComponentTransferElement.instance.in1_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEComponentTransferElement.height')
  @DocsEditable()
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGFEComponentTransferElement.instance.height_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEComponentTransferElement.result')
  @DocsEditable()
  AnimatedString get result => wrap_jso(_blink.BlinkSVGFEComponentTransferElement.instance.result_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEComponentTransferElement.width')
  @DocsEditable()
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGFEComponentTransferElement.instance.width_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEComponentTransferElement.x')
  @DocsEditable()
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGFEComponentTransferElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEComponentTransferElement.y')
  @DocsEditable()
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGFEComponentTransferElement.instance.y_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static FECompositeElement internalCreateFECompositeElement() {
    return new FECompositeElement._internalWrap();
  }

  external factory FECompositeElement._internalWrap();

  @Deprecated("Internal Use Only")
  FECompositeElement.internal_() : super.internal_();

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
  AnimatedString get in1 => wrap_jso(_blink.BlinkSVGFECompositeElement.instance.in1_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFECompositeElement.in2')
  @DocsEditable()
  AnimatedString get in2 => wrap_jso(_blink.BlinkSVGFECompositeElement.instance.in2_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFECompositeElement.k1')
  @DocsEditable()
  AnimatedNumber get k1 => wrap_jso(_blink.BlinkSVGFECompositeElement.instance.k1_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFECompositeElement.k2')
  @DocsEditable()
  AnimatedNumber get k2 => wrap_jso(_blink.BlinkSVGFECompositeElement.instance.k2_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFECompositeElement.k3')
  @DocsEditable()
  AnimatedNumber get k3 => wrap_jso(_blink.BlinkSVGFECompositeElement.instance.k3_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFECompositeElement.k4')
  @DocsEditable()
  AnimatedNumber get k4 => wrap_jso(_blink.BlinkSVGFECompositeElement.instance.k4_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFECompositeElement.operator')
  @DocsEditable()
  AnimatedEnumeration get operator => wrap_jso(_blink.BlinkSVGFECompositeElement.instance.operator_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFECompositeElement.height')
  @DocsEditable()
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGFECompositeElement.instance.height_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFECompositeElement.result')
  @DocsEditable()
  AnimatedString get result => wrap_jso(_blink.BlinkSVGFECompositeElement.instance.result_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFECompositeElement.width')
  @DocsEditable()
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGFECompositeElement.instance.width_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFECompositeElement.x')
  @DocsEditable()
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGFECompositeElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFECompositeElement.y')
  @DocsEditable()
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGFECompositeElement.instance.y_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static FEConvolveMatrixElement internalCreateFEConvolveMatrixElement() {
    return new FEConvolveMatrixElement._internalWrap();
  }

  external factory FEConvolveMatrixElement._internalWrap();

  @Deprecated("Internal Use Only")
  FEConvolveMatrixElement.internal_() : super.internal_();

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
  AnimatedNumber get bias => wrap_jso(_blink.BlinkSVGFEConvolveMatrixElement.instance.bias_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEConvolveMatrixElement.divisor')
  @DocsEditable()
  AnimatedNumber get divisor => wrap_jso(_blink.BlinkSVGFEConvolveMatrixElement.instance.divisor_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEConvolveMatrixElement.edgeMode')
  @DocsEditable()
  AnimatedEnumeration get edgeMode => wrap_jso(_blink.BlinkSVGFEConvolveMatrixElement.instance.edgeMode_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEConvolveMatrixElement.in1')
  @DocsEditable()
  AnimatedString get in1 => wrap_jso(_blink.BlinkSVGFEConvolveMatrixElement.instance.in1_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEConvolveMatrixElement.kernelMatrix')
  @DocsEditable()
  AnimatedNumberList get kernelMatrix => wrap_jso(_blink.BlinkSVGFEConvolveMatrixElement.instance.kernelMatrix_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEConvolveMatrixElement.kernelUnitLengthX')
  @DocsEditable()
  AnimatedNumber get kernelUnitLengthX => wrap_jso(_blink.BlinkSVGFEConvolveMatrixElement.instance.kernelUnitLengthX_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEConvolveMatrixElement.kernelUnitLengthY')
  @DocsEditable()
  AnimatedNumber get kernelUnitLengthY => wrap_jso(_blink.BlinkSVGFEConvolveMatrixElement.instance.kernelUnitLengthY_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEConvolveMatrixElement.orderX')
  @DocsEditable()
  AnimatedInteger get orderX => wrap_jso(_blink.BlinkSVGFEConvolveMatrixElement.instance.orderX_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEConvolveMatrixElement.orderY')
  @DocsEditable()
  AnimatedInteger get orderY => wrap_jso(_blink.BlinkSVGFEConvolveMatrixElement.instance.orderY_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEConvolveMatrixElement.preserveAlpha')
  @DocsEditable()
  AnimatedBoolean get preserveAlpha => wrap_jso(_blink.BlinkSVGFEConvolveMatrixElement.instance.preserveAlpha_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEConvolveMatrixElement.targetX')
  @DocsEditable()
  AnimatedInteger get targetX => wrap_jso(_blink.BlinkSVGFEConvolveMatrixElement.instance.targetX_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEConvolveMatrixElement.targetY')
  @DocsEditable()
  AnimatedInteger get targetY => wrap_jso(_blink.BlinkSVGFEConvolveMatrixElement.instance.targetY_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEConvolveMatrixElement.height')
  @DocsEditable()
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGFEConvolveMatrixElement.instance.height_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEConvolveMatrixElement.result')
  @DocsEditable()
  AnimatedString get result => wrap_jso(_blink.BlinkSVGFEConvolveMatrixElement.instance.result_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEConvolveMatrixElement.width')
  @DocsEditable()
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGFEConvolveMatrixElement.instance.width_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEConvolveMatrixElement.x')
  @DocsEditable()
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGFEConvolveMatrixElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEConvolveMatrixElement.y')
  @DocsEditable()
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGFEConvolveMatrixElement.instance.y_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static FEDiffuseLightingElement internalCreateFEDiffuseLightingElement() {
    return new FEDiffuseLightingElement._internalWrap();
  }

  external factory FEDiffuseLightingElement._internalWrap();

  @Deprecated("Internal Use Only")
  FEDiffuseLightingElement.internal_() : super.internal_();

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
  AnimatedNumber get diffuseConstant => wrap_jso(_blink.BlinkSVGFEDiffuseLightingElement.instance.diffuseConstant_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEDiffuseLightingElement.in1')
  @DocsEditable()
  AnimatedString get in1 => wrap_jso(_blink.BlinkSVGFEDiffuseLightingElement.instance.in1_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEDiffuseLightingElement.kernelUnitLengthX')
  @DocsEditable()
  AnimatedNumber get kernelUnitLengthX => wrap_jso(_blink.BlinkSVGFEDiffuseLightingElement.instance.kernelUnitLengthX_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEDiffuseLightingElement.kernelUnitLengthY')
  @DocsEditable()
  AnimatedNumber get kernelUnitLengthY => wrap_jso(_blink.BlinkSVGFEDiffuseLightingElement.instance.kernelUnitLengthY_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEDiffuseLightingElement.surfaceScale')
  @DocsEditable()
  AnimatedNumber get surfaceScale => wrap_jso(_blink.BlinkSVGFEDiffuseLightingElement.instance.surfaceScale_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEDiffuseLightingElement.height')
  @DocsEditable()
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGFEDiffuseLightingElement.instance.height_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEDiffuseLightingElement.result')
  @DocsEditable()
  AnimatedString get result => wrap_jso(_blink.BlinkSVGFEDiffuseLightingElement.instance.result_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEDiffuseLightingElement.width')
  @DocsEditable()
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGFEDiffuseLightingElement.instance.width_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEDiffuseLightingElement.x')
  @DocsEditable()
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGFEDiffuseLightingElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEDiffuseLightingElement.y')
  @DocsEditable()
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGFEDiffuseLightingElement.instance.y_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static FEDisplacementMapElement internalCreateFEDisplacementMapElement() {
    return new FEDisplacementMapElement._internalWrap();
  }

  external factory FEDisplacementMapElement._internalWrap();

  @Deprecated("Internal Use Only")
  FEDisplacementMapElement.internal_() : super.internal_();

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
  AnimatedString get in1 => wrap_jso(_blink.BlinkSVGFEDisplacementMapElement.instance.in1_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEDisplacementMapElement.in2')
  @DocsEditable()
  AnimatedString get in2 => wrap_jso(_blink.BlinkSVGFEDisplacementMapElement.instance.in2_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEDisplacementMapElement.scale')
  @DocsEditable()
  AnimatedNumber get scale => wrap_jso(_blink.BlinkSVGFEDisplacementMapElement.instance.scale_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEDisplacementMapElement.xChannelSelector')
  @DocsEditable()
  AnimatedEnumeration get xChannelSelector => wrap_jso(_blink.BlinkSVGFEDisplacementMapElement.instance.xChannelSelector_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEDisplacementMapElement.yChannelSelector')
  @DocsEditable()
  AnimatedEnumeration get yChannelSelector => wrap_jso(_blink.BlinkSVGFEDisplacementMapElement.instance.yChannelSelector_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEDisplacementMapElement.height')
  @DocsEditable()
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGFEDisplacementMapElement.instance.height_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEDisplacementMapElement.result')
  @DocsEditable()
  AnimatedString get result => wrap_jso(_blink.BlinkSVGFEDisplacementMapElement.instance.result_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEDisplacementMapElement.width')
  @DocsEditable()
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGFEDisplacementMapElement.instance.width_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEDisplacementMapElement.x')
  @DocsEditable()
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGFEDisplacementMapElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEDisplacementMapElement.y')
  @DocsEditable()
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGFEDisplacementMapElement.instance.y_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static FEDistantLightElement internalCreateFEDistantLightElement() {
    return new FEDistantLightElement._internalWrap();
  }

  external factory FEDistantLightElement._internalWrap();

  @Deprecated("Internal Use Only")
  FEDistantLightElement.internal_() : super.internal_();

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
  AnimatedNumber get azimuth => wrap_jso(_blink.BlinkSVGFEDistantLightElement.instance.azimuth_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEDistantLightElement.elevation')
  @DocsEditable()
  AnimatedNumber get elevation => wrap_jso(_blink.BlinkSVGFEDistantLightElement.instance.elevation_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static FEFloodElement internalCreateFEFloodElement() {
    return new FEFloodElement._internalWrap();
  }

  external factory FEFloodElement._internalWrap();

  @Deprecated("Internal Use Only")
  FEFloodElement.internal_() : super.internal_();

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
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGFEFloodElement.instance.height_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEFloodElement.result')
  @DocsEditable()
  AnimatedString get result => wrap_jso(_blink.BlinkSVGFEFloodElement.instance.result_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEFloodElement.width')
  @DocsEditable()
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGFEFloodElement.instance.width_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEFloodElement.x')
  @DocsEditable()
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGFEFloodElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEFloodElement.y')
  @DocsEditable()
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGFEFloodElement.instance.y_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static FEFuncAElement internalCreateFEFuncAElement() {
    return new FEFuncAElement._internalWrap();
  }

  external factory FEFuncAElement._internalWrap();

  @Deprecated("Internal Use Only")
  FEFuncAElement.internal_() : super.internal_();

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


  @Deprecated("Internal Use Only")
  static FEFuncBElement internalCreateFEFuncBElement() {
    return new FEFuncBElement._internalWrap();
  }

  external factory FEFuncBElement._internalWrap();

  @Deprecated("Internal Use Only")
  FEFuncBElement.internal_() : super.internal_();

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


  @Deprecated("Internal Use Only")
  static FEFuncGElement internalCreateFEFuncGElement() {
    return new FEFuncGElement._internalWrap();
  }

  external factory FEFuncGElement._internalWrap();

  @Deprecated("Internal Use Only")
  FEFuncGElement.internal_() : super.internal_();

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


  @Deprecated("Internal Use Only")
  static FEFuncRElement internalCreateFEFuncRElement() {
    return new FEFuncRElement._internalWrap();
  }

  external factory FEFuncRElement._internalWrap();

  @Deprecated("Internal Use Only")
  FEFuncRElement.internal_() : super.internal_();

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


  @Deprecated("Internal Use Only")
  static FEGaussianBlurElement internalCreateFEGaussianBlurElement() {
    return new FEGaussianBlurElement._internalWrap();
  }

  external factory FEGaussianBlurElement._internalWrap();

  @Deprecated("Internal Use Only")
  FEGaussianBlurElement.internal_() : super.internal_();

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
  AnimatedString get in1 => wrap_jso(_blink.BlinkSVGFEGaussianBlurElement.instance.in1_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEGaussianBlurElement.stdDeviationX')
  @DocsEditable()
  AnimatedNumber get stdDeviationX => wrap_jso(_blink.BlinkSVGFEGaussianBlurElement.instance.stdDeviationX_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEGaussianBlurElement.stdDeviationY')
  @DocsEditable()
  AnimatedNumber get stdDeviationY => wrap_jso(_blink.BlinkSVGFEGaussianBlurElement.instance.stdDeviationY_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEGaussianBlurElement.setStdDeviation')
  @DocsEditable()
  void setStdDeviation(num stdDeviationX, num stdDeviationY) => _blink.BlinkSVGFEGaussianBlurElement.instance.setStdDeviation_Callback_2_(unwrap_jso(this), stdDeviationX, stdDeviationY);
  
  @DomName('SVGFEGaussianBlurElement.height')
  @DocsEditable()
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGFEGaussianBlurElement.instance.height_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEGaussianBlurElement.result')
  @DocsEditable()
  AnimatedString get result => wrap_jso(_blink.BlinkSVGFEGaussianBlurElement.instance.result_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEGaussianBlurElement.width')
  @DocsEditable()
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGFEGaussianBlurElement.instance.width_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEGaussianBlurElement.x')
  @DocsEditable()
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGFEGaussianBlurElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEGaussianBlurElement.y')
  @DocsEditable()
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGFEGaussianBlurElement.instance.y_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static FEImageElement internalCreateFEImageElement() {
    return new FEImageElement._internalWrap();
  }

  external factory FEImageElement._internalWrap();

  @Deprecated("Internal Use Only")
  FEImageElement.internal_() : super.internal_();

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
  AnimatedPreserveAspectRatio get preserveAspectRatio => wrap_jso(_blink.BlinkSVGFEImageElement.instance.preserveAspectRatio_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEImageElement.height')
  @DocsEditable()
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGFEImageElement.instance.height_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEImageElement.result')
  @DocsEditable()
  AnimatedString get result => wrap_jso(_blink.BlinkSVGFEImageElement.instance.result_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEImageElement.width')
  @DocsEditable()
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGFEImageElement.instance.width_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEImageElement.x')
  @DocsEditable()
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGFEImageElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEImageElement.y')
  @DocsEditable()
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGFEImageElement.instance.y_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEImageElement.href')
  @DocsEditable()
  AnimatedString get href => wrap_jso(_blink.BlinkSVGFEImageElement.instance.href_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static FEMergeElement internalCreateFEMergeElement() {
    return new FEMergeElement._internalWrap();
  }

  external factory FEMergeElement._internalWrap();

  @Deprecated("Internal Use Only")
  FEMergeElement.internal_() : super.internal_();

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
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGFEMergeElement.instance.height_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEMergeElement.result')
  @DocsEditable()
  AnimatedString get result => wrap_jso(_blink.BlinkSVGFEMergeElement.instance.result_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEMergeElement.width')
  @DocsEditable()
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGFEMergeElement.instance.width_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEMergeElement.x')
  @DocsEditable()
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGFEMergeElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEMergeElement.y')
  @DocsEditable()
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGFEMergeElement.instance.y_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static FEMergeNodeElement internalCreateFEMergeNodeElement() {
    return new FEMergeNodeElement._internalWrap();
  }

  external factory FEMergeNodeElement._internalWrap();

  @Deprecated("Internal Use Only")
  FEMergeNodeElement.internal_() : super.internal_();

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
  AnimatedString get in1 => wrap_jso(_blink.BlinkSVGFEMergeNodeElement.instance.in1_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static FEMorphologyElement internalCreateFEMorphologyElement() {
    return new FEMorphologyElement._internalWrap();
  }

  external factory FEMorphologyElement._internalWrap();

  @Deprecated("Internal Use Only")
  FEMorphologyElement.internal_() : super.internal_();

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
  AnimatedString get in1 => wrap_jso(_blink.BlinkSVGFEMorphologyElement.instance.in1_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEMorphologyElement.operator')
  @DocsEditable()
  AnimatedEnumeration get operator => wrap_jso(_blink.BlinkSVGFEMorphologyElement.instance.operator_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEMorphologyElement.radiusX')
  @DocsEditable()
  AnimatedNumber get radiusX => wrap_jso(_blink.BlinkSVGFEMorphologyElement.instance.radiusX_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEMorphologyElement.radiusY')
  @DocsEditable()
  AnimatedNumber get radiusY => wrap_jso(_blink.BlinkSVGFEMorphologyElement.instance.radiusY_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEMorphologyElement.height')
  @DocsEditable()
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGFEMorphologyElement.instance.height_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEMorphologyElement.result')
  @DocsEditable()
  AnimatedString get result => wrap_jso(_blink.BlinkSVGFEMorphologyElement.instance.result_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEMorphologyElement.width')
  @DocsEditable()
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGFEMorphologyElement.instance.width_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEMorphologyElement.x')
  @DocsEditable()
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGFEMorphologyElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEMorphologyElement.y')
  @DocsEditable()
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGFEMorphologyElement.instance.y_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static FEOffsetElement internalCreateFEOffsetElement() {
    return new FEOffsetElement._internalWrap();
  }

  external factory FEOffsetElement._internalWrap();

  @Deprecated("Internal Use Only")
  FEOffsetElement.internal_() : super.internal_();

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
  AnimatedNumber get dx => wrap_jso(_blink.BlinkSVGFEOffsetElement.instance.dx_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEOffsetElement.dy')
  @DocsEditable()
  AnimatedNumber get dy => wrap_jso(_blink.BlinkSVGFEOffsetElement.instance.dy_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEOffsetElement.in1')
  @DocsEditable()
  AnimatedString get in1 => wrap_jso(_blink.BlinkSVGFEOffsetElement.instance.in1_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEOffsetElement.height')
  @DocsEditable()
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGFEOffsetElement.instance.height_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEOffsetElement.result')
  @DocsEditable()
  AnimatedString get result => wrap_jso(_blink.BlinkSVGFEOffsetElement.instance.result_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEOffsetElement.width')
  @DocsEditable()
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGFEOffsetElement.instance.width_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEOffsetElement.x')
  @DocsEditable()
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGFEOffsetElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEOffsetElement.y')
  @DocsEditable()
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGFEOffsetElement.instance.y_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static FEPointLightElement internalCreateFEPointLightElement() {
    return new FEPointLightElement._internalWrap();
  }

  external factory FEPointLightElement._internalWrap();

  @Deprecated("Internal Use Only")
  FEPointLightElement.internal_() : super.internal_();

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
  AnimatedNumber get x => wrap_jso(_blink.BlinkSVGFEPointLightElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEPointLightElement.y')
  @DocsEditable()
  AnimatedNumber get y => wrap_jso(_blink.BlinkSVGFEPointLightElement.instance.y_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFEPointLightElement.z')
  @DocsEditable()
  AnimatedNumber get z => wrap_jso(_blink.BlinkSVGFEPointLightElement.instance.z_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static FESpecularLightingElement internalCreateFESpecularLightingElement() {
    return new FESpecularLightingElement._internalWrap();
  }

  external factory FESpecularLightingElement._internalWrap();

  @Deprecated("Internal Use Only")
  FESpecularLightingElement.internal_() : super.internal_();

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
  AnimatedString get in1 => wrap_jso(_blink.BlinkSVGFESpecularLightingElement.instance.in1_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFESpecularLightingElement.kernelUnitLengthX')
  @DocsEditable()
  @Experimental() // untriaged
  AnimatedNumber get kernelUnitLengthX => wrap_jso(_blink.BlinkSVGFESpecularLightingElement.instance.kernelUnitLengthX_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFESpecularLightingElement.kernelUnitLengthY')
  @DocsEditable()
  @Experimental() // untriaged
  AnimatedNumber get kernelUnitLengthY => wrap_jso(_blink.BlinkSVGFESpecularLightingElement.instance.kernelUnitLengthY_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFESpecularLightingElement.specularConstant')
  @DocsEditable()
  AnimatedNumber get specularConstant => wrap_jso(_blink.BlinkSVGFESpecularLightingElement.instance.specularConstant_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFESpecularLightingElement.specularExponent')
  @DocsEditable()
  AnimatedNumber get specularExponent => wrap_jso(_blink.BlinkSVGFESpecularLightingElement.instance.specularExponent_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFESpecularLightingElement.surfaceScale')
  @DocsEditable()
  AnimatedNumber get surfaceScale => wrap_jso(_blink.BlinkSVGFESpecularLightingElement.instance.surfaceScale_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFESpecularLightingElement.height')
  @DocsEditable()
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGFESpecularLightingElement.instance.height_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFESpecularLightingElement.result')
  @DocsEditable()
  AnimatedString get result => wrap_jso(_blink.BlinkSVGFESpecularLightingElement.instance.result_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFESpecularLightingElement.width')
  @DocsEditable()
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGFESpecularLightingElement.instance.width_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFESpecularLightingElement.x')
  @DocsEditable()
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGFESpecularLightingElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFESpecularLightingElement.y')
  @DocsEditable()
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGFESpecularLightingElement.instance.y_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static FESpotLightElement internalCreateFESpotLightElement() {
    return new FESpotLightElement._internalWrap();
  }

  external factory FESpotLightElement._internalWrap();

  @Deprecated("Internal Use Only")
  FESpotLightElement.internal_() : super.internal_();

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
  AnimatedNumber get limitingConeAngle => wrap_jso(_blink.BlinkSVGFESpotLightElement.instance.limitingConeAngle_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFESpotLightElement.pointsAtX')
  @DocsEditable()
  AnimatedNumber get pointsAtX => wrap_jso(_blink.BlinkSVGFESpotLightElement.instance.pointsAtX_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFESpotLightElement.pointsAtY')
  @DocsEditable()
  AnimatedNumber get pointsAtY => wrap_jso(_blink.BlinkSVGFESpotLightElement.instance.pointsAtY_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFESpotLightElement.pointsAtZ')
  @DocsEditable()
  AnimatedNumber get pointsAtZ => wrap_jso(_blink.BlinkSVGFESpotLightElement.instance.pointsAtZ_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFESpotLightElement.specularExponent')
  @DocsEditable()
  AnimatedNumber get specularExponent => wrap_jso(_blink.BlinkSVGFESpotLightElement.instance.specularExponent_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFESpotLightElement.x')
  @DocsEditable()
  AnimatedNumber get x => wrap_jso(_blink.BlinkSVGFESpotLightElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFESpotLightElement.y')
  @DocsEditable()
  AnimatedNumber get y => wrap_jso(_blink.BlinkSVGFESpotLightElement.instance.y_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFESpotLightElement.z')
  @DocsEditable()
  AnimatedNumber get z => wrap_jso(_blink.BlinkSVGFESpotLightElement.instance.z_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static FETileElement internalCreateFETileElement() {
    return new FETileElement._internalWrap();
  }

  external factory FETileElement._internalWrap();

  @Deprecated("Internal Use Only")
  FETileElement.internal_() : super.internal_();

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
  AnimatedString get in1 => wrap_jso(_blink.BlinkSVGFETileElement.instance.in1_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFETileElement.height')
  @DocsEditable()
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGFETileElement.instance.height_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFETileElement.result')
  @DocsEditable()
  AnimatedString get result => wrap_jso(_blink.BlinkSVGFETileElement.instance.result_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFETileElement.width')
  @DocsEditable()
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGFETileElement.instance.width_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFETileElement.x')
  @DocsEditable()
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGFETileElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFETileElement.y')
  @DocsEditable()
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGFETileElement.instance.y_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static FETurbulenceElement internalCreateFETurbulenceElement() {
    return new FETurbulenceElement._internalWrap();
  }

  external factory FETurbulenceElement._internalWrap();

  @Deprecated("Internal Use Only")
  FETurbulenceElement.internal_() : super.internal_();

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
  AnimatedNumber get baseFrequencyX => wrap_jso(_blink.BlinkSVGFETurbulenceElement.instance.baseFrequencyX_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFETurbulenceElement.baseFrequencyY')
  @DocsEditable()
  AnimatedNumber get baseFrequencyY => wrap_jso(_blink.BlinkSVGFETurbulenceElement.instance.baseFrequencyY_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFETurbulenceElement.numOctaves')
  @DocsEditable()
  AnimatedInteger get numOctaves => wrap_jso(_blink.BlinkSVGFETurbulenceElement.instance.numOctaves_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFETurbulenceElement.seed')
  @DocsEditable()
  AnimatedNumber get seed => wrap_jso(_blink.BlinkSVGFETurbulenceElement.instance.seed_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFETurbulenceElement.stitchTiles')
  @DocsEditable()
  AnimatedEnumeration get stitchTiles => wrap_jso(_blink.BlinkSVGFETurbulenceElement.instance.stitchTiles_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFETurbulenceElement.type')
  @DocsEditable()
  AnimatedEnumeration get type => wrap_jso(_blink.BlinkSVGFETurbulenceElement.instance.type_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFETurbulenceElement.height')
  @DocsEditable()
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGFETurbulenceElement.instance.height_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFETurbulenceElement.result')
  @DocsEditable()
  AnimatedString get result => wrap_jso(_blink.BlinkSVGFETurbulenceElement.instance.result_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFETurbulenceElement.width')
  @DocsEditable()
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGFETurbulenceElement.instance.width_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFETurbulenceElement.x')
  @DocsEditable()
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGFETurbulenceElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFETurbulenceElement.y')
  @DocsEditable()
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGFETurbulenceElement.instance.y_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static FilterElement internalCreateFilterElement() {
    return new FilterElement._internalWrap();
  }

  external factory FilterElement._internalWrap();

  @Deprecated("Internal Use Only")
  FilterElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FilterElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFilterElement.filterUnits')
  @DocsEditable()
  AnimatedEnumeration get filterUnits => wrap_jso(_blink.BlinkSVGFilterElement.instance.filterUnits_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFilterElement.height')
  @DocsEditable()
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGFilterElement.instance.height_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFilterElement.primitiveUnits')
  @DocsEditable()
  AnimatedEnumeration get primitiveUnits => wrap_jso(_blink.BlinkSVGFilterElement.instance.primitiveUnits_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFilterElement.width')
  @DocsEditable()
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGFilterElement.instance.width_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFilterElement.x')
  @DocsEditable()
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGFilterElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFilterElement.y')
  @DocsEditable()
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGFilterElement.instance.y_Getter_(unwrap_jso(this)));
  
  @DomName('SVGFilterElement.href')
  @DocsEditable()
  AnimatedString get href => wrap_jso(_blink.BlinkSVGFilterElement.instance.href_Getter_(unwrap_jso(this)));
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFilterPrimitiveStandardAttributes')
@Unstable()
abstract class FilterPrimitiveStandardAttributes extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory FilterPrimitiveStandardAttributes._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFilterPrimitiveStandardAttributes.height')
  @DocsEditable()
  AnimatedLength get height;

  @DomName('SVGFilterPrimitiveStandardAttributes.result')
  @DocsEditable()
  AnimatedString get result;

  @DomName('SVGFilterPrimitiveStandardAttributes.width')
  @DocsEditable()
  AnimatedLength get width;

  @DomName('SVGFilterPrimitiveStandardAttributes.x')
  @DocsEditable()
  AnimatedLength get x;

  @DomName('SVGFilterPrimitiveStandardAttributes.y')
  @DocsEditable()
  AnimatedLength get y;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFitToViewBox')
@Unstable()
abstract class FitToViewBox extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory FitToViewBox._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFitToViewBox.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio;

  @DomName('SVGFitToViewBox.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox;

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


  @Deprecated("Internal Use Only")
  static ForeignObjectElement internalCreateForeignObjectElement() {
    return new ForeignObjectElement._internalWrap();
  }

  external factory ForeignObjectElement._internalWrap();

  @Deprecated("Internal Use Only")
  ForeignObjectElement.internal_() : super.internal_();

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
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGForeignObjectElement.instance.height_Getter_(unwrap_jso(this)));
  
  @DomName('SVGForeignObjectElement.width')
  @DocsEditable()
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGForeignObjectElement.instance.width_Getter_(unwrap_jso(this)));
  
  @DomName('SVGForeignObjectElement.x')
  @DocsEditable()
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGForeignObjectElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGForeignObjectElement.y')
  @DocsEditable()
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGForeignObjectElement.instance.y_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static GElement internalCreateGElement() {
    return new GElement._internalWrap();
  }

  external factory GElement._internalWrap();

  @Deprecated("Internal Use Only")
  GElement.internal_() : super.internal_();

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


  @Deprecated("Internal Use Only")
  static GeometryElement internalCreateGeometryElement() {
    return new GeometryElement._internalWrap();
  }

  external factory GeometryElement._internalWrap();

  @Deprecated("Internal Use Only")
  GeometryElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  GeometryElement.created() : super.created();

  @DomName('SVGGeometryElement.isPointInFill')
  @DocsEditable()
  @Experimental() // untriaged
  bool isPointInFill(Point point) => _blink.BlinkSVGGeometryElement.instance.isPointInFill_Callback_1_(unwrap_jso(this), unwrap_jso(point));
  
  @DomName('SVGGeometryElement.isPointInStroke')
  @DocsEditable()
  @Experimental() // untriaged
  bool isPointInStroke(Point point) => _blink.BlinkSVGGeometryElement.instance.isPointInStroke_Callback_1_(unwrap_jso(this), unwrap_jso(point));
  
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


  @Deprecated("Internal Use Only")
  static GraphicsElement internalCreateGraphicsElement() {
    return new GraphicsElement._internalWrap();
  }

  external factory GraphicsElement._internalWrap();

  @Deprecated("Internal Use Only")
  GraphicsElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  GraphicsElement.created() : super.created();

  @DomName('SVGGraphicsElement.farthestViewportElement')
  @DocsEditable()
  @Experimental() // untriaged
  SvgElement get farthestViewportElement => wrap_jso(_blink.BlinkSVGGraphicsElement.instance.farthestViewportElement_Getter_(unwrap_jso(this)));
  
  @DomName('SVGGraphicsElement.nearestViewportElement')
  @DocsEditable()
  @Experimental() // untriaged
  SvgElement get nearestViewportElement => wrap_jso(_blink.BlinkSVGGraphicsElement.instance.nearestViewportElement_Getter_(unwrap_jso(this)));
  
  @DomName('SVGGraphicsElement.transform')
  @DocsEditable()
  @Experimental() // untriaged
  AnimatedTransformList get transform => wrap_jso(_blink.BlinkSVGGraphicsElement.instance.transform_Getter_(unwrap_jso(this)));
  
  @DomName('SVGGraphicsElement.getBBox')
  @DocsEditable()
  @Experimental() // untriaged
  Rect getBBox() => wrap_jso(_blink.BlinkSVGGraphicsElement.instance.getBBox_Callback_0_(unwrap_jso(this)));
  
  @DomName('SVGGraphicsElement.getCTM')
  @DocsEditable()
  @Experimental() // untriaged
  Matrix getCtm() => wrap_jso(_blink.BlinkSVGGraphicsElement.instance.getCTM_Callback_0_(unwrap_jso(this)));
  
  @DomName('SVGGraphicsElement.getScreenCTM')
  @DocsEditable()
  @Experimental() // untriaged
  Matrix getScreenCtm() => wrap_jso(_blink.BlinkSVGGraphicsElement.instance.getScreenCTM_Callback_0_(unwrap_jso(this)));
  
  @DomName('SVGGraphicsElement.getTransformToElement')
  @DocsEditable()
  @Experimental() // untriaged
  Matrix getTransformToElement(SvgElement element) => wrap_jso(_blink.BlinkSVGGraphicsElement.instance.getTransformToElement_Callback_1_(unwrap_jso(this), unwrap_jso(element)));
  
  @DomName('SVGGraphicsElement.requiredExtensions')
  @DocsEditable()
  @Experimental() // untriaged
  StringList get requiredExtensions => wrap_jso(_blink.BlinkSVGGraphicsElement.instance.requiredExtensions_Getter_(unwrap_jso(this)));
  
  @DomName('SVGGraphicsElement.requiredFeatures')
  @DocsEditable()
  @Experimental() // untriaged
  StringList get requiredFeatures => wrap_jso(_blink.BlinkSVGGraphicsElement.instance.requiredFeatures_Getter_(unwrap_jso(this)));
  
  @DomName('SVGGraphicsElement.systemLanguage')
  @DocsEditable()
  @Experimental() // untriaged
  StringList get systemLanguage => wrap_jso(_blink.BlinkSVGGraphicsElement.instance.systemLanguage_Getter_(unwrap_jso(this)));
  
  @DomName('SVGGraphicsElement.hasExtension')
  @DocsEditable()
  @Experimental() // untriaged
  bool hasExtension(String extension) => _blink.BlinkSVGGraphicsElement.instance.hasExtension_Callback_1_(unwrap_jso(this), extension);
  
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


  @Deprecated("Internal Use Only")
  static ImageElement internalCreateImageElement() {
    return new ImageElement._internalWrap();
  }

  external factory ImageElement._internalWrap();

  @Deprecated("Internal Use Only")
  ImageElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  ImageElement.created() : super.created();

  @DomName('SVGImageElement.height')
  @DocsEditable()
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGImageElement.instance.height_Getter_(unwrap_jso(this)));
  
  @DomName('SVGImageElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio => wrap_jso(_blink.BlinkSVGImageElement.instance.preserveAspectRatio_Getter_(unwrap_jso(this)));
  
  @DomName('SVGImageElement.width')
  @DocsEditable()
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGImageElement.instance.width_Getter_(unwrap_jso(this)));
  
  @DomName('SVGImageElement.x')
  @DocsEditable()
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGImageElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGImageElement.y')
  @DocsEditable()
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGImageElement.instance.y_Getter_(unwrap_jso(this)));
  
  @DomName('SVGImageElement.href')
  @DocsEditable()
  AnimatedString get href => wrap_jso(_blink.BlinkSVGImageElement.instance.href_Getter_(unwrap_jso(this)));
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGLength')
@Unstable()
class Length extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory Length._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static Length internalCreateLength() {
    return new Length._internalWrap();
  }

  factory Length._internalWrap() {
    return new Length.internal_();
  }

  @Deprecated("Internal Use Only")
  Length.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

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
  int get unitType => _blink.BlinkSVGLength.instance.unitType_Getter_(unwrap_jso(this));
  
  @DomName('SVGLength.value')
  @DocsEditable()
  num get value => _blink.BlinkSVGLength.instance.value_Getter_(unwrap_jso(this));
  
  @DomName('SVGLength.value')
  @DocsEditable()
  set value(num value) => _blink.BlinkSVGLength.instance.value_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGLength.valueAsString')
  @DocsEditable()
  String get valueAsString => _blink.BlinkSVGLength.instance.valueAsString_Getter_(unwrap_jso(this));
  
  @DomName('SVGLength.valueAsString')
  @DocsEditable()
  set valueAsString(String value) => _blink.BlinkSVGLength.instance.valueAsString_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGLength.valueInSpecifiedUnits')
  @DocsEditable()
  num get valueInSpecifiedUnits => _blink.BlinkSVGLength.instance.valueInSpecifiedUnits_Getter_(unwrap_jso(this));
  
  @DomName('SVGLength.valueInSpecifiedUnits')
  @DocsEditable()
  set valueInSpecifiedUnits(num value) => _blink.BlinkSVGLength.instance.valueInSpecifiedUnits_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGLength.convertToSpecifiedUnits')
  @DocsEditable()
  void convertToSpecifiedUnits(int unitType) => _blink.BlinkSVGLength.instance.convertToSpecifiedUnits_Callback_1_(unwrap_jso(this), unitType);
  
  @DomName('SVGLength.newValueSpecifiedUnits')
  @DocsEditable()
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) => _blink.BlinkSVGLength.instance.newValueSpecifiedUnits_Callback_2_(unwrap_jso(this), unitType, valueInSpecifiedUnits);
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGLengthList')
@Unstable()
class LengthList extends DartHtmlDomObject with ListMixin<Length>, ImmutableListMixin<Length> implements List<Length> {
  // To suppress missing implicit constructor warnings.
  factory LengthList._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static LengthList internalCreateLengthList() {
    return new LengthList._internalWrap();
  }

  factory LengthList._internalWrap() {
    return new LengthList.internal_();
  }

  @Deprecated("Internal Use Only")
  LengthList.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SVGLengthList.length')
  @DocsEditable()
  @Experimental() // untriaged
  int get length => _blink.BlinkSVGLengthList.instance.length_Getter_(unwrap_jso(this));
  
  @DomName('SVGLengthList.numberOfItems')
  @DocsEditable()
  int get numberOfItems => _blink.BlinkSVGLengthList.instance.numberOfItems_Getter_(unwrap_jso(this));
  
  Length operator[](int index) {
    if (index < 0 || index >= length)
      throw new RangeError.index(index, this);
    return getItem(index);
  }

  void operator[]=(int index, Length value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Length> mixins.
  // Length is the element type.


  set length(int value) {
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

  @DomName('SVGLengthList.__setter__')
  @DocsEditable()
  @Experimental() // untriaged
  void __setter__(int index, Length newItem) => _blink.BlinkSVGLengthList.instance.$__setter___Callback_2_(unwrap_jso(this), index, unwrap_jso(newItem));
  
  @DomName('SVGLengthList.appendItem')
  @DocsEditable()
  Length appendItem(Length newItem) => wrap_jso(_blink.BlinkSVGLengthList.instance.appendItem_Callback_1_(unwrap_jso(this), unwrap_jso(newItem)));
  
  @DomName('SVGLengthList.clear')
  @DocsEditable()
  void clear() => _blink.BlinkSVGLengthList.instance.clear_Callback_0_(unwrap_jso(this));
  
  @DomName('SVGLengthList.getItem')
  @DocsEditable()
  Length getItem(int index) => wrap_jso(_blink.BlinkSVGLengthList.instance.getItem_Callback_1_(unwrap_jso(this), index));
  
  @DomName('SVGLengthList.initialize')
  @DocsEditable()
  Length initialize(Length newItem) => wrap_jso(_blink.BlinkSVGLengthList.instance.initialize_Callback_1_(unwrap_jso(this), unwrap_jso(newItem)));
  
  @DomName('SVGLengthList.insertItemBefore')
  @DocsEditable()
  Length insertItemBefore(Length newItem, int index) => wrap_jso(_blink.BlinkSVGLengthList.instance.insertItemBefore_Callback_2_(unwrap_jso(this), unwrap_jso(newItem), index));
  
  @DomName('SVGLengthList.removeItem')
  @DocsEditable()
  Length removeItem(int index) => wrap_jso(_blink.BlinkSVGLengthList.instance.removeItem_Callback_1_(unwrap_jso(this), index));
  
  @DomName('SVGLengthList.replaceItem')
  @DocsEditable()
  Length replaceItem(Length newItem, int index) => wrap_jso(_blink.BlinkSVGLengthList.instance.replaceItem_Callback_2_(unwrap_jso(this), unwrap_jso(newItem), index));
  
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


  @Deprecated("Internal Use Only")
  static LineElement internalCreateLineElement() {
    return new LineElement._internalWrap();
  }

  external factory LineElement._internalWrap();

  @Deprecated("Internal Use Only")
  LineElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  LineElement.created() : super.created();

  @DomName('SVGLineElement.x1')
  @DocsEditable()
  AnimatedLength get x1 => wrap_jso(_blink.BlinkSVGLineElement.instance.x1_Getter_(unwrap_jso(this)));
  
  @DomName('SVGLineElement.x2')
  @DocsEditable()
  AnimatedLength get x2 => wrap_jso(_blink.BlinkSVGLineElement.instance.x2_Getter_(unwrap_jso(this)));
  
  @DomName('SVGLineElement.y1')
  @DocsEditable()
  AnimatedLength get y1 => wrap_jso(_blink.BlinkSVGLineElement.instance.y1_Getter_(unwrap_jso(this)));
  
  @DomName('SVGLineElement.y2')
  @DocsEditable()
  AnimatedLength get y2 => wrap_jso(_blink.BlinkSVGLineElement.instance.y2_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static LinearGradientElement internalCreateLinearGradientElement() {
    return new LinearGradientElement._internalWrap();
  }

  external factory LinearGradientElement._internalWrap();

  @Deprecated("Internal Use Only")
  LinearGradientElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  LinearGradientElement.created() : super.created();

  @DomName('SVGLinearGradientElement.x1')
  @DocsEditable()
  AnimatedLength get x1 => wrap_jso(_blink.BlinkSVGLinearGradientElement.instance.x1_Getter_(unwrap_jso(this)));
  
  @DomName('SVGLinearGradientElement.x2')
  @DocsEditable()
  AnimatedLength get x2 => wrap_jso(_blink.BlinkSVGLinearGradientElement.instance.x2_Getter_(unwrap_jso(this)));
  
  @DomName('SVGLinearGradientElement.y1')
  @DocsEditable()
  AnimatedLength get y1 => wrap_jso(_blink.BlinkSVGLinearGradientElement.instance.y1_Getter_(unwrap_jso(this)));
  
  @DomName('SVGLinearGradientElement.y2')
  @DocsEditable()
  AnimatedLength get y2 => wrap_jso(_blink.BlinkSVGLinearGradientElement.instance.y2_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static MarkerElement internalCreateMarkerElement() {
    return new MarkerElement._internalWrap();
  }

  external factory MarkerElement._internalWrap();

  @Deprecated("Internal Use Only")
  MarkerElement.internal_() : super.internal_();

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
  AnimatedLength get markerHeight => wrap_jso(_blink.BlinkSVGMarkerElement.instance.markerHeight_Getter_(unwrap_jso(this)));
  
  @DomName('SVGMarkerElement.markerUnits')
  @DocsEditable()
  AnimatedEnumeration get markerUnits => wrap_jso(_blink.BlinkSVGMarkerElement.instance.markerUnits_Getter_(unwrap_jso(this)));
  
  @DomName('SVGMarkerElement.markerWidth')
  @DocsEditable()
  AnimatedLength get markerWidth => wrap_jso(_blink.BlinkSVGMarkerElement.instance.markerWidth_Getter_(unwrap_jso(this)));
  
  @DomName('SVGMarkerElement.orientAngle')
  @DocsEditable()
  AnimatedAngle get orientAngle => wrap_jso(_blink.BlinkSVGMarkerElement.instance.orientAngle_Getter_(unwrap_jso(this)));
  
  @DomName('SVGMarkerElement.orientType')
  @DocsEditable()
  AnimatedEnumeration get orientType => wrap_jso(_blink.BlinkSVGMarkerElement.instance.orientType_Getter_(unwrap_jso(this)));
  
  @DomName('SVGMarkerElement.refX')
  @DocsEditable()
  AnimatedLength get refX => wrap_jso(_blink.BlinkSVGMarkerElement.instance.refX_Getter_(unwrap_jso(this)));
  
  @DomName('SVGMarkerElement.refY')
  @DocsEditable()
  AnimatedLength get refY => wrap_jso(_blink.BlinkSVGMarkerElement.instance.refY_Getter_(unwrap_jso(this)));
  
  @DomName('SVGMarkerElement.setOrientToAngle')
  @DocsEditable()
  void setOrientToAngle(Angle angle) => _blink.BlinkSVGMarkerElement.instance.setOrientToAngle_Callback_1_(unwrap_jso(this), unwrap_jso(angle));
  
  @DomName('SVGMarkerElement.setOrientToAuto')
  @DocsEditable()
  void setOrientToAuto() => _blink.BlinkSVGMarkerElement.instance.setOrientToAuto_Callback_0_(unwrap_jso(this));
  
  @DomName('SVGMarkerElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio => wrap_jso(_blink.BlinkSVGMarkerElement.instance.preserveAspectRatio_Getter_(unwrap_jso(this)));
  
  @DomName('SVGMarkerElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox => wrap_jso(_blink.BlinkSVGMarkerElement.instance.viewBox_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static MaskElement internalCreateMaskElement() {
    return new MaskElement._internalWrap();
  }

  external factory MaskElement._internalWrap();

  @Deprecated("Internal Use Only")
  MaskElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  MaskElement.created() : super.created();

  @DomName('SVGMaskElement.height')
  @DocsEditable()
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGMaskElement.instance.height_Getter_(unwrap_jso(this)));
  
  @DomName('SVGMaskElement.maskContentUnits')
  @DocsEditable()
  AnimatedEnumeration get maskContentUnits => wrap_jso(_blink.BlinkSVGMaskElement.instance.maskContentUnits_Getter_(unwrap_jso(this)));
  
  @DomName('SVGMaskElement.maskUnits')
  @DocsEditable()
  AnimatedEnumeration get maskUnits => wrap_jso(_blink.BlinkSVGMaskElement.instance.maskUnits_Getter_(unwrap_jso(this)));
  
  @DomName('SVGMaskElement.width')
  @DocsEditable()
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGMaskElement.instance.width_Getter_(unwrap_jso(this)));
  
  @DomName('SVGMaskElement.x')
  @DocsEditable()
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGMaskElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGMaskElement.y')
  @DocsEditable()
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGMaskElement.instance.y_Getter_(unwrap_jso(this)));
  
  @DomName('SVGMaskElement.requiredExtensions')
  @DocsEditable()
  StringList get requiredExtensions => wrap_jso(_blink.BlinkSVGMaskElement.instance.requiredExtensions_Getter_(unwrap_jso(this)));
  
  @DomName('SVGMaskElement.requiredFeatures')
  @DocsEditable()
  StringList get requiredFeatures => wrap_jso(_blink.BlinkSVGMaskElement.instance.requiredFeatures_Getter_(unwrap_jso(this)));
  
  @DomName('SVGMaskElement.systemLanguage')
  @DocsEditable()
  StringList get systemLanguage => wrap_jso(_blink.BlinkSVGMaskElement.instance.systemLanguage_Getter_(unwrap_jso(this)));
  
  @DomName('SVGMaskElement.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) => _blink.BlinkSVGMaskElement.instance.hasExtension_Callback_1_(unwrap_jso(this), extension);
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGMatrix')
@Unstable()
class Matrix extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory Matrix._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static Matrix internalCreateMatrix() {
    return new Matrix._internalWrap();
  }

  factory Matrix._internalWrap() {
    return new Matrix.internal_();
  }

  @Deprecated("Internal Use Only")
  Matrix.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SVGMatrix.a')
  @DocsEditable()
  num get a => _blink.BlinkSVGMatrix.instance.a_Getter_(unwrap_jso(this));
  
  @DomName('SVGMatrix.a')
  @DocsEditable()
  set a(num value) => _blink.BlinkSVGMatrix.instance.a_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGMatrix.b')
  @DocsEditable()
  num get b => _blink.BlinkSVGMatrix.instance.b_Getter_(unwrap_jso(this));
  
  @DomName('SVGMatrix.b')
  @DocsEditable()
  set b(num value) => _blink.BlinkSVGMatrix.instance.b_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGMatrix.c')
  @DocsEditable()
  num get c => _blink.BlinkSVGMatrix.instance.c_Getter_(unwrap_jso(this));
  
  @DomName('SVGMatrix.c')
  @DocsEditable()
  set c(num value) => _blink.BlinkSVGMatrix.instance.c_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGMatrix.d')
  @DocsEditable()
  num get d => _blink.BlinkSVGMatrix.instance.d_Getter_(unwrap_jso(this));
  
  @DomName('SVGMatrix.d')
  @DocsEditable()
  set d(num value) => _blink.BlinkSVGMatrix.instance.d_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGMatrix.e')
  @DocsEditable()
  num get e => _blink.BlinkSVGMatrix.instance.e_Getter_(unwrap_jso(this));
  
  @DomName('SVGMatrix.e')
  @DocsEditable()
  set e(num value) => _blink.BlinkSVGMatrix.instance.e_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGMatrix.f')
  @DocsEditable()
  num get f => _blink.BlinkSVGMatrix.instance.f_Getter_(unwrap_jso(this));
  
  @DomName('SVGMatrix.f')
  @DocsEditable()
  set f(num value) => _blink.BlinkSVGMatrix.instance.f_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGMatrix.flipX')
  @DocsEditable()
  Matrix flipX() => wrap_jso(_blink.BlinkSVGMatrix.instance.flipX_Callback_0_(unwrap_jso(this)));
  
  @DomName('SVGMatrix.flipY')
  @DocsEditable()
  Matrix flipY() => wrap_jso(_blink.BlinkSVGMatrix.instance.flipY_Callback_0_(unwrap_jso(this)));
  
  @DomName('SVGMatrix.inverse')
  @DocsEditable()
  Matrix inverse() => wrap_jso(_blink.BlinkSVGMatrix.instance.inverse_Callback_0_(unwrap_jso(this)));
  
  @DomName('SVGMatrix.multiply')
  @DocsEditable()
  Matrix multiply(Matrix secondMatrix) => wrap_jso(_blink.BlinkSVGMatrix.instance.multiply_Callback_1_(unwrap_jso(this), unwrap_jso(secondMatrix)));
  
  @DomName('SVGMatrix.rotate')
  @DocsEditable()
  Matrix rotate(num angle) => wrap_jso(_blink.BlinkSVGMatrix.instance.rotate_Callback_1_(unwrap_jso(this), angle));
  
  @DomName('SVGMatrix.rotateFromVector')
  @DocsEditable()
  Matrix rotateFromVector(num x, num y) => wrap_jso(_blink.BlinkSVGMatrix.instance.rotateFromVector_Callback_2_(unwrap_jso(this), x, y));
  
  @DomName('SVGMatrix.scale')
  @DocsEditable()
  Matrix scale(num scaleFactor) => wrap_jso(_blink.BlinkSVGMatrix.instance.scale_Callback_1_(unwrap_jso(this), scaleFactor));
  
  @DomName('SVGMatrix.scaleNonUniform')
  @DocsEditable()
  Matrix scaleNonUniform(num scaleFactorX, num scaleFactorY) => wrap_jso(_blink.BlinkSVGMatrix.instance.scaleNonUniform_Callback_2_(unwrap_jso(this), scaleFactorX, scaleFactorY));
  
  @DomName('SVGMatrix.skewX')
  @DocsEditable()
  Matrix skewX(num angle) => wrap_jso(_blink.BlinkSVGMatrix.instance.skewX_Callback_1_(unwrap_jso(this), angle));
  
  @DomName('SVGMatrix.skewY')
  @DocsEditable()
  Matrix skewY(num angle) => wrap_jso(_blink.BlinkSVGMatrix.instance.skewY_Callback_1_(unwrap_jso(this), angle));
  
  @DomName('SVGMatrix.translate')
  @DocsEditable()
  Matrix translate(num x, num y) => wrap_jso(_blink.BlinkSVGMatrix.instance.translate_Callback_2_(unwrap_jso(this), x, y));
  
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


  @Deprecated("Internal Use Only")
  static MetadataElement internalCreateMetadataElement() {
    return new MetadataElement._internalWrap();
  }

  external factory MetadataElement._internalWrap();

  @Deprecated("Internal Use Only")
  MetadataElement.internal_() : super.internal_();

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
class Number extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory Number._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static Number internalCreateNumber() {
    return new Number._internalWrap();
  }

  factory Number._internalWrap() {
    return new Number.internal_();
  }

  @Deprecated("Internal Use Only")
  Number.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SVGNumber.value')
  @DocsEditable()
  num get value => _blink.BlinkSVGNumber.instance.value_Getter_(unwrap_jso(this));
  
  @DomName('SVGNumber.value')
  @DocsEditable()
  set value(num value) => _blink.BlinkSVGNumber.instance.value_Setter_(unwrap_jso(this), value);
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGNumberList')
@Unstable()
class NumberList extends DartHtmlDomObject with ListMixin<Number>, ImmutableListMixin<Number> implements List<Number> {
  // To suppress missing implicit constructor warnings.
  factory NumberList._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static NumberList internalCreateNumberList() {
    return new NumberList._internalWrap();
  }

  factory NumberList._internalWrap() {
    return new NumberList.internal_();
  }

  @Deprecated("Internal Use Only")
  NumberList.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SVGNumberList.length')
  @DocsEditable()
  @Experimental() // untriaged
  int get length => _blink.BlinkSVGNumberList.instance.length_Getter_(unwrap_jso(this));
  
  @DomName('SVGNumberList.numberOfItems')
  @DocsEditable()
  int get numberOfItems => _blink.BlinkSVGNumberList.instance.numberOfItems_Getter_(unwrap_jso(this));
  
  Number operator[](int index) {
    if (index < 0 || index >= length)
      throw new RangeError.index(index, this);
    return getItem(index);
  }

  void operator[]=(int index, Number value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Number> mixins.
  // Number is the element type.


  set length(int value) {
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

  @DomName('SVGNumberList.__setter__')
  @DocsEditable()
  @Experimental() // untriaged
  void __setter__(int index, Number newItem) => _blink.BlinkSVGNumberList.instance.$__setter___Callback_2_(unwrap_jso(this), index, unwrap_jso(newItem));
  
  @DomName('SVGNumberList.appendItem')
  @DocsEditable()
  Number appendItem(Number newItem) => wrap_jso(_blink.BlinkSVGNumberList.instance.appendItem_Callback_1_(unwrap_jso(this), unwrap_jso(newItem)));
  
  @DomName('SVGNumberList.clear')
  @DocsEditable()
  void clear() => _blink.BlinkSVGNumberList.instance.clear_Callback_0_(unwrap_jso(this));
  
  @DomName('SVGNumberList.getItem')
  @DocsEditable()
  Number getItem(int index) => wrap_jso(_blink.BlinkSVGNumberList.instance.getItem_Callback_1_(unwrap_jso(this), index));
  
  @DomName('SVGNumberList.initialize')
  @DocsEditable()
  Number initialize(Number newItem) => wrap_jso(_blink.BlinkSVGNumberList.instance.initialize_Callback_1_(unwrap_jso(this), unwrap_jso(newItem)));
  
  @DomName('SVGNumberList.insertItemBefore')
  @DocsEditable()
  Number insertItemBefore(Number newItem, int index) => wrap_jso(_blink.BlinkSVGNumberList.instance.insertItemBefore_Callback_2_(unwrap_jso(this), unwrap_jso(newItem), index));
  
  @DomName('SVGNumberList.removeItem')
  @DocsEditable()
  Number removeItem(int index) => wrap_jso(_blink.BlinkSVGNumberList.instance.removeItem_Callback_1_(unwrap_jso(this), index));
  
  @DomName('SVGNumberList.replaceItem')
  @DocsEditable()
  Number replaceItem(Number newItem, int index) => wrap_jso(_blink.BlinkSVGNumberList.instance.replaceItem_Callback_2_(unwrap_jso(this), unwrap_jso(newItem), index));
  
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


  @Deprecated("Internal Use Only")
  static PathElement internalCreatePathElement() {
    return new PathElement._internalWrap();
  }

  external factory PathElement._internalWrap();

  @Deprecated("Internal Use Only")
  PathElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  PathElement.created() : super.created();

  @DomName('SVGPathElement.animatedNormalizedPathSegList')
  @DocsEditable()
  PathSegList get animatedNormalizedPathSegList => wrap_jso(_blink.BlinkSVGPathElement.instance.animatedNormalizedPathSegList_Getter_(unwrap_jso(this)));
  
  @DomName('SVGPathElement.animatedPathSegList')
  @DocsEditable()
  PathSegList get animatedPathSegList => wrap_jso(_blink.BlinkSVGPathElement.instance.animatedPathSegList_Getter_(unwrap_jso(this)));
  
  @DomName('SVGPathElement.normalizedPathSegList')
  @DocsEditable()
  PathSegList get normalizedPathSegList => wrap_jso(_blink.BlinkSVGPathElement.instance.normalizedPathSegList_Getter_(unwrap_jso(this)));
  
  @DomName('SVGPathElement.pathLength')
  @DocsEditable()
  AnimatedNumber get pathLength => wrap_jso(_blink.BlinkSVGPathElement.instance.pathLength_Getter_(unwrap_jso(this)));
  
  @DomName('SVGPathElement.pathSegList')
  @DocsEditable()
  PathSegList get pathSegList => wrap_jso(_blink.BlinkSVGPathElement.instance.pathSegList_Getter_(unwrap_jso(this)));
  
  @DomName('SVGPathElement.createSVGPathSegArcAbs')
  @DocsEditable()
  PathSegArcAbs createSvgPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) => wrap_jso(_blink.BlinkSVGPathElement.instance.createSVGPathSegArcAbs_Callback_7_(unwrap_jso(this), x, y, r1, r2, angle, largeArcFlag, sweepFlag));
  
  @DomName('SVGPathElement.createSVGPathSegArcRel')
  @DocsEditable()
  PathSegArcRel createSvgPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) => wrap_jso(_blink.BlinkSVGPathElement.instance.createSVGPathSegArcRel_Callback_7_(unwrap_jso(this), x, y, r1, r2, angle, largeArcFlag, sweepFlag));
  
  @DomName('SVGPathElement.createSVGPathSegClosePath')
  @DocsEditable()
  PathSegClosePath createSvgPathSegClosePath() => wrap_jso(_blink.BlinkSVGPathElement.instance.createSVGPathSegClosePath_Callback_0_(unwrap_jso(this)));
  
  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicAbs')
  @DocsEditable()
  PathSegCurvetoCubicAbs createSvgPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) => wrap_jso(_blink.BlinkSVGPathElement.instance.createSVGPathSegCurvetoCubicAbs_Callback_6_(unwrap_jso(this), x, y, x1, y1, x2, y2));
  
  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicRel')
  @DocsEditable()
  PathSegCurvetoCubicRel createSvgPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) => wrap_jso(_blink.BlinkSVGPathElement.instance.createSVGPathSegCurvetoCubicRel_Callback_6_(unwrap_jso(this), x, y, x1, y1, x2, y2));
  
  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicSmoothAbs')
  @DocsEditable()
  PathSegCurvetoCubicSmoothAbs createSvgPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) => wrap_jso(_blink.BlinkSVGPathElement.instance.createSVGPathSegCurvetoCubicSmoothAbs_Callback_4_(unwrap_jso(this), x, y, x2, y2));
  
  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicSmoothRel')
  @DocsEditable()
  PathSegCurvetoCubicSmoothRel createSvgPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) => wrap_jso(_blink.BlinkSVGPathElement.instance.createSVGPathSegCurvetoCubicSmoothRel_Callback_4_(unwrap_jso(this), x, y, x2, y2));
  
  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticAbs')
  @DocsEditable()
  PathSegCurvetoQuadraticAbs createSvgPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) => wrap_jso(_blink.BlinkSVGPathElement.instance.createSVGPathSegCurvetoQuadraticAbs_Callback_4_(unwrap_jso(this), x, y, x1, y1));
  
  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticRel')
  @DocsEditable()
  PathSegCurvetoQuadraticRel createSvgPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) => wrap_jso(_blink.BlinkSVGPathElement.instance.createSVGPathSegCurvetoQuadraticRel_Callback_4_(unwrap_jso(this), x, y, x1, y1));
  
  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothAbs')
  @DocsEditable()
  PathSegCurvetoQuadraticSmoothAbs createSvgPathSegCurvetoQuadraticSmoothAbs(num x, num y) => wrap_jso(_blink.BlinkSVGPathElement.instance.createSVGPathSegCurvetoQuadraticSmoothAbs_Callback_2_(unwrap_jso(this), x, y));
  
  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothRel')
  @DocsEditable()
  PathSegCurvetoQuadraticSmoothRel createSvgPathSegCurvetoQuadraticSmoothRel(num x, num y) => wrap_jso(_blink.BlinkSVGPathElement.instance.createSVGPathSegCurvetoQuadraticSmoothRel_Callback_2_(unwrap_jso(this), x, y));
  
  @DomName('SVGPathElement.createSVGPathSegLinetoAbs')
  @DocsEditable()
  PathSegLinetoAbs createSvgPathSegLinetoAbs(num x, num y) => wrap_jso(_blink.BlinkSVGPathElement.instance.createSVGPathSegLinetoAbs_Callback_2_(unwrap_jso(this), x, y));
  
  @DomName('SVGPathElement.createSVGPathSegLinetoHorizontalAbs')
  @DocsEditable()
  PathSegLinetoHorizontalAbs createSvgPathSegLinetoHorizontalAbs(num x) => wrap_jso(_blink.BlinkSVGPathElement.instance.createSVGPathSegLinetoHorizontalAbs_Callback_1_(unwrap_jso(this), x));
  
  @DomName('SVGPathElement.createSVGPathSegLinetoHorizontalRel')
  @DocsEditable()
  PathSegLinetoHorizontalRel createSvgPathSegLinetoHorizontalRel(num x) => wrap_jso(_blink.BlinkSVGPathElement.instance.createSVGPathSegLinetoHorizontalRel_Callback_1_(unwrap_jso(this), x));
  
  @DomName('SVGPathElement.createSVGPathSegLinetoRel')
  @DocsEditable()
  PathSegLinetoRel createSvgPathSegLinetoRel(num x, num y) => wrap_jso(_blink.BlinkSVGPathElement.instance.createSVGPathSegLinetoRel_Callback_2_(unwrap_jso(this), x, y));
  
  @DomName('SVGPathElement.createSVGPathSegLinetoVerticalAbs')
  @DocsEditable()
  PathSegLinetoVerticalAbs createSvgPathSegLinetoVerticalAbs(num y) => wrap_jso(_blink.BlinkSVGPathElement.instance.createSVGPathSegLinetoVerticalAbs_Callback_1_(unwrap_jso(this), y));
  
  @DomName('SVGPathElement.createSVGPathSegLinetoVerticalRel')
  @DocsEditable()
  PathSegLinetoVerticalRel createSvgPathSegLinetoVerticalRel(num y) => wrap_jso(_blink.BlinkSVGPathElement.instance.createSVGPathSegLinetoVerticalRel_Callback_1_(unwrap_jso(this), y));
  
  @DomName('SVGPathElement.createSVGPathSegMovetoAbs')
  @DocsEditable()
  PathSegMovetoAbs createSvgPathSegMovetoAbs(num x, num y) => wrap_jso(_blink.BlinkSVGPathElement.instance.createSVGPathSegMovetoAbs_Callback_2_(unwrap_jso(this), x, y));
  
  @DomName('SVGPathElement.createSVGPathSegMovetoRel')
  @DocsEditable()
  PathSegMovetoRel createSvgPathSegMovetoRel(num x, num y) => wrap_jso(_blink.BlinkSVGPathElement.instance.createSVGPathSegMovetoRel_Callback_2_(unwrap_jso(this), x, y));
  
  @DomName('SVGPathElement.getPathSegAtLength')
  @DocsEditable()
  int getPathSegAtLength(num distance) => _blink.BlinkSVGPathElement.instance.getPathSegAtLength_Callback_1_(unwrap_jso(this), distance);
  
  @DomName('SVGPathElement.getPointAtLength')
  @DocsEditable()
  Point getPointAtLength(num distance) => wrap_jso(_blink.BlinkSVGPathElement.instance.getPointAtLength_Callback_1_(unwrap_jso(this), distance));
  
  @DomName('SVGPathElement.getTotalLength')
  @DocsEditable()
  num getTotalLength() => _blink.BlinkSVGPathElement.instance.getTotalLength_Callback_0_(unwrap_jso(this));
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSeg')
@Unstable()
class PathSeg extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory PathSeg._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static PathSeg internalCreatePathSeg() {
    return new PathSeg._internalWrap();
  }

  factory PathSeg._internalWrap() {
    return new PathSeg.internal_();
  }

  @Deprecated("Internal Use Only")
  PathSeg.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

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
  int get pathSegType => _blink.BlinkSVGPathSeg.instance.pathSegType_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSeg.pathSegTypeAsLetter')
  @DocsEditable()
  String get pathSegTypeAsLetter => _blink.BlinkSVGPathSeg.instance.pathSegTypeAsLetter_Getter_(unwrap_jso(this));
  
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


  @Deprecated("Internal Use Only")
  static PathSegArcAbs internalCreatePathSegArcAbs() {
    return new PathSegArcAbs._internalWrap();
  }

  external factory PathSegArcAbs._internalWrap();

  @Deprecated("Internal Use Only")
  PathSegArcAbs.internal_() : super.internal_();


  @DomName('SVGPathSegArcAbs.angle')
  @DocsEditable()
  num get angle => _blink.BlinkSVGPathSegArcAbs.instance.angle_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegArcAbs.angle')
  @DocsEditable()
  set angle(num value) => _blink.BlinkSVGPathSegArcAbs.instance.angle_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegArcAbs.largeArcFlag')
  @DocsEditable()
  bool get largeArcFlag => _blink.BlinkSVGPathSegArcAbs.instance.largeArcFlag_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegArcAbs.largeArcFlag')
  @DocsEditable()
  set largeArcFlag(bool value) => _blink.BlinkSVGPathSegArcAbs.instance.largeArcFlag_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegArcAbs.r1')
  @DocsEditable()
  num get r1 => _blink.BlinkSVGPathSegArcAbs.instance.r1_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegArcAbs.r1')
  @DocsEditable()
  set r1(num value) => _blink.BlinkSVGPathSegArcAbs.instance.r1_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegArcAbs.r2')
  @DocsEditable()
  num get r2 => _blink.BlinkSVGPathSegArcAbs.instance.r2_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegArcAbs.r2')
  @DocsEditable()
  set r2(num value) => _blink.BlinkSVGPathSegArcAbs.instance.r2_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegArcAbs.sweepFlag')
  @DocsEditable()
  bool get sweepFlag => _blink.BlinkSVGPathSegArcAbs.instance.sweepFlag_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegArcAbs.sweepFlag')
  @DocsEditable()
  set sweepFlag(bool value) => _blink.BlinkSVGPathSegArcAbs.instance.sweepFlag_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegArcAbs.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegArcAbs.instance.x_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegArcAbs.x')
  @DocsEditable()
  set x(num value) => _blink.BlinkSVGPathSegArcAbs.instance.x_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegArcAbs.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegArcAbs.instance.y_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegArcAbs.y')
  @DocsEditable()
  set y(num value) => _blink.BlinkSVGPathSegArcAbs.instance.y_Setter_(unwrap_jso(this), value);
  
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


  @Deprecated("Internal Use Only")
  static PathSegArcRel internalCreatePathSegArcRel() {
    return new PathSegArcRel._internalWrap();
  }

  external factory PathSegArcRel._internalWrap();

  @Deprecated("Internal Use Only")
  PathSegArcRel.internal_() : super.internal_();


  @DomName('SVGPathSegArcRel.angle')
  @DocsEditable()
  num get angle => _blink.BlinkSVGPathSegArcRel.instance.angle_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegArcRel.angle')
  @DocsEditable()
  set angle(num value) => _blink.BlinkSVGPathSegArcRel.instance.angle_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegArcRel.largeArcFlag')
  @DocsEditable()
  bool get largeArcFlag => _blink.BlinkSVGPathSegArcRel.instance.largeArcFlag_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegArcRel.largeArcFlag')
  @DocsEditable()
  set largeArcFlag(bool value) => _blink.BlinkSVGPathSegArcRel.instance.largeArcFlag_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegArcRel.r1')
  @DocsEditable()
  num get r1 => _blink.BlinkSVGPathSegArcRel.instance.r1_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegArcRel.r1')
  @DocsEditable()
  set r1(num value) => _blink.BlinkSVGPathSegArcRel.instance.r1_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegArcRel.r2')
  @DocsEditable()
  num get r2 => _blink.BlinkSVGPathSegArcRel.instance.r2_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegArcRel.r2')
  @DocsEditable()
  set r2(num value) => _blink.BlinkSVGPathSegArcRel.instance.r2_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegArcRel.sweepFlag')
  @DocsEditable()
  bool get sweepFlag => _blink.BlinkSVGPathSegArcRel.instance.sweepFlag_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegArcRel.sweepFlag')
  @DocsEditable()
  set sweepFlag(bool value) => _blink.BlinkSVGPathSegArcRel.instance.sweepFlag_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegArcRel.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegArcRel.instance.x_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegArcRel.x')
  @DocsEditable()
  set x(num value) => _blink.BlinkSVGPathSegArcRel.instance.x_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegArcRel.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegArcRel.instance.y_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegArcRel.y')
  @DocsEditable()
  set y(num value) => _blink.BlinkSVGPathSegArcRel.instance.y_Setter_(unwrap_jso(this), value);
  
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


  @Deprecated("Internal Use Only")
  static PathSegClosePath internalCreatePathSegClosePath() {
    return new PathSegClosePath._internalWrap();
  }

  external factory PathSegClosePath._internalWrap();

  @Deprecated("Internal Use Only")
  PathSegClosePath.internal_() : super.internal_();


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


  @Deprecated("Internal Use Only")
  static PathSegCurvetoCubicAbs internalCreatePathSegCurvetoCubicAbs() {
    return new PathSegCurvetoCubicAbs._internalWrap();
  }

  external factory PathSegCurvetoCubicAbs._internalWrap();

  @Deprecated("Internal Use Only")
  PathSegCurvetoCubicAbs.internal_() : super.internal_();


  @DomName('SVGPathSegCurvetoCubicAbs.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegCurvetoCubicAbs.instance.x_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoCubicAbs.x')
  @DocsEditable()
  set x(num value) => _blink.BlinkSVGPathSegCurvetoCubicAbs.instance.x_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegCurvetoCubicAbs.x1')
  @DocsEditable()
  num get x1 => _blink.BlinkSVGPathSegCurvetoCubicAbs.instance.x1_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoCubicAbs.x1')
  @DocsEditable()
  set x1(num value) => _blink.BlinkSVGPathSegCurvetoCubicAbs.instance.x1_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegCurvetoCubicAbs.x2')
  @DocsEditable()
  num get x2 => _blink.BlinkSVGPathSegCurvetoCubicAbs.instance.x2_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoCubicAbs.x2')
  @DocsEditable()
  set x2(num value) => _blink.BlinkSVGPathSegCurvetoCubicAbs.instance.x2_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegCurvetoCubicAbs.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegCurvetoCubicAbs.instance.y_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoCubicAbs.y')
  @DocsEditable()
  set y(num value) => _blink.BlinkSVGPathSegCurvetoCubicAbs.instance.y_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegCurvetoCubicAbs.y1')
  @DocsEditable()
  num get y1 => _blink.BlinkSVGPathSegCurvetoCubicAbs.instance.y1_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoCubicAbs.y1')
  @DocsEditable()
  set y1(num value) => _blink.BlinkSVGPathSegCurvetoCubicAbs.instance.y1_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegCurvetoCubicAbs.y2')
  @DocsEditable()
  num get y2 => _blink.BlinkSVGPathSegCurvetoCubicAbs.instance.y2_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoCubicAbs.y2')
  @DocsEditable()
  set y2(num value) => _blink.BlinkSVGPathSegCurvetoCubicAbs.instance.y2_Setter_(unwrap_jso(this), value);
  
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


  @Deprecated("Internal Use Only")
  static PathSegCurvetoCubicRel internalCreatePathSegCurvetoCubicRel() {
    return new PathSegCurvetoCubicRel._internalWrap();
  }

  external factory PathSegCurvetoCubicRel._internalWrap();

  @Deprecated("Internal Use Only")
  PathSegCurvetoCubicRel.internal_() : super.internal_();


  @DomName('SVGPathSegCurvetoCubicRel.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegCurvetoCubicRel.instance.x_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoCubicRel.x')
  @DocsEditable()
  set x(num value) => _blink.BlinkSVGPathSegCurvetoCubicRel.instance.x_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegCurvetoCubicRel.x1')
  @DocsEditable()
  num get x1 => _blink.BlinkSVGPathSegCurvetoCubicRel.instance.x1_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoCubicRel.x1')
  @DocsEditable()
  set x1(num value) => _blink.BlinkSVGPathSegCurvetoCubicRel.instance.x1_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegCurvetoCubicRel.x2')
  @DocsEditable()
  num get x2 => _blink.BlinkSVGPathSegCurvetoCubicRel.instance.x2_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoCubicRel.x2')
  @DocsEditable()
  set x2(num value) => _blink.BlinkSVGPathSegCurvetoCubicRel.instance.x2_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegCurvetoCubicRel.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegCurvetoCubicRel.instance.y_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoCubicRel.y')
  @DocsEditable()
  set y(num value) => _blink.BlinkSVGPathSegCurvetoCubicRel.instance.y_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegCurvetoCubicRel.y1')
  @DocsEditable()
  num get y1 => _blink.BlinkSVGPathSegCurvetoCubicRel.instance.y1_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoCubicRel.y1')
  @DocsEditable()
  set y1(num value) => _blink.BlinkSVGPathSegCurvetoCubicRel.instance.y1_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegCurvetoCubicRel.y2')
  @DocsEditable()
  num get y2 => _blink.BlinkSVGPathSegCurvetoCubicRel.instance.y2_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoCubicRel.y2')
  @DocsEditable()
  set y2(num value) => _blink.BlinkSVGPathSegCurvetoCubicRel.instance.y2_Setter_(unwrap_jso(this), value);
  
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


  @Deprecated("Internal Use Only")
  static PathSegCurvetoCubicSmoothAbs internalCreatePathSegCurvetoCubicSmoothAbs() {
    return new PathSegCurvetoCubicSmoothAbs._internalWrap();
  }

  external factory PathSegCurvetoCubicSmoothAbs._internalWrap();

  @Deprecated("Internal Use Only")
  PathSegCurvetoCubicSmoothAbs.internal_() : super.internal_();


  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegCurvetoCubicSmoothAbs.instance.x_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x')
  @DocsEditable()
  set x(num value) => _blink.BlinkSVGPathSegCurvetoCubicSmoothAbs.instance.x_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x2')
  @DocsEditable()
  num get x2 => _blink.BlinkSVGPathSegCurvetoCubicSmoothAbs.instance.x2_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x2')
  @DocsEditable()
  set x2(num value) => _blink.BlinkSVGPathSegCurvetoCubicSmoothAbs.instance.x2_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegCurvetoCubicSmoothAbs.instance.y_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y')
  @DocsEditable()
  set y(num value) => _blink.BlinkSVGPathSegCurvetoCubicSmoothAbs.instance.y_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y2')
  @DocsEditable()
  num get y2 => _blink.BlinkSVGPathSegCurvetoCubicSmoothAbs.instance.y2_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y2')
  @DocsEditable()
  set y2(num value) => _blink.BlinkSVGPathSegCurvetoCubicSmoothAbs.instance.y2_Setter_(unwrap_jso(this), value);
  
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


  @Deprecated("Internal Use Only")
  static PathSegCurvetoCubicSmoothRel internalCreatePathSegCurvetoCubicSmoothRel() {
    return new PathSegCurvetoCubicSmoothRel._internalWrap();
  }

  external factory PathSegCurvetoCubicSmoothRel._internalWrap();

  @Deprecated("Internal Use Only")
  PathSegCurvetoCubicSmoothRel.internal_() : super.internal_();


  @DomName('SVGPathSegCurvetoCubicSmoothRel.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegCurvetoCubicSmoothRel.instance.x_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoCubicSmoothRel.x')
  @DocsEditable()
  set x(num value) => _blink.BlinkSVGPathSegCurvetoCubicSmoothRel.instance.x_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegCurvetoCubicSmoothRel.x2')
  @DocsEditable()
  num get x2 => _blink.BlinkSVGPathSegCurvetoCubicSmoothRel.instance.x2_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoCubicSmoothRel.x2')
  @DocsEditable()
  set x2(num value) => _blink.BlinkSVGPathSegCurvetoCubicSmoothRel.instance.x2_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegCurvetoCubicSmoothRel.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegCurvetoCubicSmoothRel.instance.y_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoCubicSmoothRel.y')
  @DocsEditable()
  set y(num value) => _blink.BlinkSVGPathSegCurvetoCubicSmoothRel.instance.y_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegCurvetoCubicSmoothRel.y2')
  @DocsEditable()
  num get y2 => _blink.BlinkSVGPathSegCurvetoCubicSmoothRel.instance.y2_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoCubicSmoothRel.y2')
  @DocsEditable()
  set y2(num value) => _blink.BlinkSVGPathSegCurvetoCubicSmoothRel.instance.y2_Setter_(unwrap_jso(this), value);
  
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


  @Deprecated("Internal Use Only")
  static PathSegCurvetoQuadraticAbs internalCreatePathSegCurvetoQuadraticAbs() {
    return new PathSegCurvetoQuadraticAbs._internalWrap();
  }

  external factory PathSegCurvetoQuadraticAbs._internalWrap();

  @Deprecated("Internal Use Only")
  PathSegCurvetoQuadraticAbs.internal_() : super.internal_();


  @DomName('SVGPathSegCurvetoQuadraticAbs.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegCurvetoQuadraticAbs.instance.x_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoQuadraticAbs.x')
  @DocsEditable()
  set x(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticAbs.instance.x_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegCurvetoQuadraticAbs.x1')
  @DocsEditable()
  num get x1 => _blink.BlinkSVGPathSegCurvetoQuadraticAbs.instance.x1_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoQuadraticAbs.x1')
  @DocsEditable()
  set x1(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticAbs.instance.x1_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegCurvetoQuadraticAbs.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegCurvetoQuadraticAbs.instance.y_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoQuadraticAbs.y')
  @DocsEditable()
  set y(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticAbs.instance.y_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegCurvetoQuadraticAbs.y1')
  @DocsEditable()
  num get y1 => _blink.BlinkSVGPathSegCurvetoQuadraticAbs.instance.y1_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoQuadraticAbs.y1')
  @DocsEditable()
  set y1(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticAbs.instance.y1_Setter_(unwrap_jso(this), value);
  
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


  @Deprecated("Internal Use Only")
  static PathSegCurvetoQuadraticRel internalCreatePathSegCurvetoQuadraticRel() {
    return new PathSegCurvetoQuadraticRel._internalWrap();
  }

  external factory PathSegCurvetoQuadraticRel._internalWrap();

  @Deprecated("Internal Use Only")
  PathSegCurvetoQuadraticRel.internal_() : super.internal_();


  @DomName('SVGPathSegCurvetoQuadraticRel.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegCurvetoQuadraticRel.instance.x_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoQuadraticRel.x')
  @DocsEditable()
  set x(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticRel.instance.x_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegCurvetoQuadraticRel.x1')
  @DocsEditable()
  num get x1 => _blink.BlinkSVGPathSegCurvetoQuadraticRel.instance.x1_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoQuadraticRel.x1')
  @DocsEditable()
  set x1(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticRel.instance.x1_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegCurvetoQuadraticRel.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegCurvetoQuadraticRel.instance.y_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoQuadraticRel.y')
  @DocsEditable()
  set y(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticRel.instance.y_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegCurvetoQuadraticRel.y1')
  @DocsEditable()
  num get y1 => _blink.BlinkSVGPathSegCurvetoQuadraticRel.instance.y1_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoQuadraticRel.y1')
  @DocsEditable()
  set y1(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticRel.instance.y1_Setter_(unwrap_jso(this), value);
  
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


  @Deprecated("Internal Use Only")
  static PathSegCurvetoQuadraticSmoothAbs internalCreatePathSegCurvetoQuadraticSmoothAbs() {
    return new PathSegCurvetoQuadraticSmoothAbs._internalWrap();
  }

  external factory PathSegCurvetoQuadraticSmoothAbs._internalWrap();

  @Deprecated("Internal Use Only")
  PathSegCurvetoQuadraticSmoothAbs.internal_() : super.internal_();


  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegCurvetoQuadraticSmoothAbs.instance.x_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.x')
  @DocsEditable()
  set x(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticSmoothAbs.instance.x_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegCurvetoQuadraticSmoothAbs.instance.y_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.y')
  @DocsEditable()
  set y(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticSmoothAbs.instance.y_Setter_(unwrap_jso(this), value);
  
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


  @Deprecated("Internal Use Only")
  static PathSegCurvetoQuadraticSmoothRel internalCreatePathSegCurvetoQuadraticSmoothRel() {
    return new PathSegCurvetoQuadraticSmoothRel._internalWrap();
  }

  external factory PathSegCurvetoQuadraticSmoothRel._internalWrap();

  @Deprecated("Internal Use Only")
  PathSegCurvetoQuadraticSmoothRel.internal_() : super.internal_();


  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegCurvetoQuadraticSmoothRel.instance.x_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.x')
  @DocsEditable()
  set x(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticSmoothRel.instance.x_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegCurvetoQuadraticSmoothRel.instance.y_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.y')
  @DocsEditable()
  set y(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticSmoothRel.instance.y_Setter_(unwrap_jso(this), value);
  
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


  @Deprecated("Internal Use Only")
  static PathSegLinetoAbs internalCreatePathSegLinetoAbs() {
    return new PathSegLinetoAbs._internalWrap();
  }

  external factory PathSegLinetoAbs._internalWrap();

  @Deprecated("Internal Use Only")
  PathSegLinetoAbs.internal_() : super.internal_();


  @DomName('SVGPathSegLinetoAbs.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegLinetoAbs.instance.x_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegLinetoAbs.x')
  @DocsEditable()
  set x(num value) => _blink.BlinkSVGPathSegLinetoAbs.instance.x_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegLinetoAbs.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegLinetoAbs.instance.y_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegLinetoAbs.y')
  @DocsEditable()
  set y(num value) => _blink.BlinkSVGPathSegLinetoAbs.instance.y_Setter_(unwrap_jso(this), value);
  
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


  @Deprecated("Internal Use Only")
  static PathSegLinetoHorizontalAbs internalCreatePathSegLinetoHorizontalAbs() {
    return new PathSegLinetoHorizontalAbs._internalWrap();
  }

  external factory PathSegLinetoHorizontalAbs._internalWrap();

  @Deprecated("Internal Use Only")
  PathSegLinetoHorizontalAbs.internal_() : super.internal_();


  @DomName('SVGPathSegLinetoHorizontalAbs.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegLinetoHorizontalAbs.instance.x_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegLinetoHorizontalAbs.x')
  @DocsEditable()
  set x(num value) => _blink.BlinkSVGPathSegLinetoHorizontalAbs.instance.x_Setter_(unwrap_jso(this), value);
  
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


  @Deprecated("Internal Use Only")
  static PathSegLinetoHorizontalRel internalCreatePathSegLinetoHorizontalRel() {
    return new PathSegLinetoHorizontalRel._internalWrap();
  }

  external factory PathSegLinetoHorizontalRel._internalWrap();

  @Deprecated("Internal Use Only")
  PathSegLinetoHorizontalRel.internal_() : super.internal_();


  @DomName('SVGPathSegLinetoHorizontalRel.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegLinetoHorizontalRel.instance.x_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegLinetoHorizontalRel.x')
  @DocsEditable()
  set x(num value) => _blink.BlinkSVGPathSegLinetoHorizontalRel.instance.x_Setter_(unwrap_jso(this), value);
  
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


  @Deprecated("Internal Use Only")
  static PathSegLinetoRel internalCreatePathSegLinetoRel() {
    return new PathSegLinetoRel._internalWrap();
  }

  external factory PathSegLinetoRel._internalWrap();

  @Deprecated("Internal Use Only")
  PathSegLinetoRel.internal_() : super.internal_();


  @DomName('SVGPathSegLinetoRel.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegLinetoRel.instance.x_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegLinetoRel.x')
  @DocsEditable()
  set x(num value) => _blink.BlinkSVGPathSegLinetoRel.instance.x_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegLinetoRel.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegLinetoRel.instance.y_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegLinetoRel.y')
  @DocsEditable()
  set y(num value) => _blink.BlinkSVGPathSegLinetoRel.instance.y_Setter_(unwrap_jso(this), value);
  
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


  @Deprecated("Internal Use Only")
  static PathSegLinetoVerticalAbs internalCreatePathSegLinetoVerticalAbs() {
    return new PathSegLinetoVerticalAbs._internalWrap();
  }

  external factory PathSegLinetoVerticalAbs._internalWrap();

  @Deprecated("Internal Use Only")
  PathSegLinetoVerticalAbs.internal_() : super.internal_();


  @DomName('SVGPathSegLinetoVerticalAbs.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegLinetoVerticalAbs.instance.y_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegLinetoVerticalAbs.y')
  @DocsEditable()
  set y(num value) => _blink.BlinkSVGPathSegLinetoVerticalAbs.instance.y_Setter_(unwrap_jso(this), value);
  
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


  @Deprecated("Internal Use Only")
  static PathSegLinetoVerticalRel internalCreatePathSegLinetoVerticalRel() {
    return new PathSegLinetoVerticalRel._internalWrap();
  }

  external factory PathSegLinetoVerticalRel._internalWrap();

  @Deprecated("Internal Use Only")
  PathSegLinetoVerticalRel.internal_() : super.internal_();


  @DomName('SVGPathSegLinetoVerticalRel.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegLinetoVerticalRel.instance.y_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegLinetoVerticalRel.y')
  @DocsEditable()
  set y(num value) => _blink.BlinkSVGPathSegLinetoVerticalRel.instance.y_Setter_(unwrap_jso(this), value);
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSegList')
@Unstable()
class PathSegList extends DartHtmlDomObject with ListMixin<PathSeg>, ImmutableListMixin<PathSeg> implements List<PathSeg> {
  // To suppress missing implicit constructor warnings.
  factory PathSegList._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static PathSegList internalCreatePathSegList() {
    return new PathSegList._internalWrap();
  }

  factory PathSegList._internalWrap() {
    return new PathSegList.internal_();
  }

  @Deprecated("Internal Use Only")
  PathSegList.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SVGPathSegList.length')
  @DocsEditable()
  @Experimental() // untriaged
  int get length => _blink.BlinkSVGPathSegList.instance.length_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegList.numberOfItems')
  @DocsEditable()
  int get numberOfItems => _blink.BlinkSVGPathSegList.instance.numberOfItems_Getter_(unwrap_jso(this));
  
  PathSeg operator[](int index) {
    if (index < 0 || index >= length)
      throw new RangeError.index(index, this);
    return getItem(index);
  }

  void operator[]=(int index, PathSeg value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<PathSeg> mixins.
  // PathSeg is the element type.


  set length(int value) {
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

  @DomName('SVGPathSegList.__setter__')
  @DocsEditable()
  @Experimental() // untriaged
  void __setter__(int index, PathSeg newItem) => _blink.BlinkSVGPathSegList.instance.$__setter___Callback_2_(unwrap_jso(this), index, unwrap_jso(newItem));
  
  @DomName('SVGPathSegList.appendItem')
  @DocsEditable()
  PathSeg appendItem(PathSeg newItem) => wrap_jso(_blink.BlinkSVGPathSegList.instance.appendItem_Callback_1_(unwrap_jso(this), unwrap_jso(newItem)));
  
  @DomName('SVGPathSegList.clear')
  @DocsEditable()
  void clear() => _blink.BlinkSVGPathSegList.instance.clear_Callback_0_(unwrap_jso(this));
  
  @DomName('SVGPathSegList.getItem')
  @DocsEditable()
  PathSeg getItem(int index) => wrap_jso(_blink.BlinkSVGPathSegList.instance.getItem_Callback_1_(unwrap_jso(this), index));
  
  @DomName('SVGPathSegList.initialize')
  @DocsEditable()
  PathSeg initialize(PathSeg newItem) => wrap_jso(_blink.BlinkSVGPathSegList.instance.initialize_Callback_1_(unwrap_jso(this), unwrap_jso(newItem)));
  
  @DomName('SVGPathSegList.insertItemBefore')
  @DocsEditable()
  PathSeg insertItemBefore(PathSeg newItem, int index) => wrap_jso(_blink.BlinkSVGPathSegList.instance.insertItemBefore_Callback_2_(unwrap_jso(this), unwrap_jso(newItem), index));
  
  @DomName('SVGPathSegList.removeItem')
  @DocsEditable()
  PathSeg removeItem(int index) => wrap_jso(_blink.BlinkSVGPathSegList.instance.removeItem_Callback_1_(unwrap_jso(this), index));
  
  @DomName('SVGPathSegList.replaceItem')
  @DocsEditable()
  PathSeg replaceItem(PathSeg newItem, int index) => wrap_jso(_blink.BlinkSVGPathSegList.instance.replaceItem_Callback_2_(unwrap_jso(this), unwrap_jso(newItem), index));
  
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


  @Deprecated("Internal Use Only")
  static PathSegMovetoAbs internalCreatePathSegMovetoAbs() {
    return new PathSegMovetoAbs._internalWrap();
  }

  external factory PathSegMovetoAbs._internalWrap();

  @Deprecated("Internal Use Only")
  PathSegMovetoAbs.internal_() : super.internal_();


  @DomName('SVGPathSegMovetoAbs.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegMovetoAbs.instance.x_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegMovetoAbs.x')
  @DocsEditable()
  set x(num value) => _blink.BlinkSVGPathSegMovetoAbs.instance.x_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegMovetoAbs.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegMovetoAbs.instance.y_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegMovetoAbs.y')
  @DocsEditable()
  set y(num value) => _blink.BlinkSVGPathSegMovetoAbs.instance.y_Setter_(unwrap_jso(this), value);
  
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


  @Deprecated("Internal Use Only")
  static PathSegMovetoRel internalCreatePathSegMovetoRel() {
    return new PathSegMovetoRel._internalWrap();
  }

  external factory PathSegMovetoRel._internalWrap();

  @Deprecated("Internal Use Only")
  PathSegMovetoRel.internal_() : super.internal_();


  @DomName('SVGPathSegMovetoRel.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegMovetoRel.instance.x_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegMovetoRel.x')
  @DocsEditable()
  set x(num value) => _blink.BlinkSVGPathSegMovetoRel.instance.x_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPathSegMovetoRel.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegMovetoRel.instance.y_Getter_(unwrap_jso(this));
  
  @DomName('SVGPathSegMovetoRel.y')
  @DocsEditable()
  set y(num value) => _blink.BlinkSVGPathSegMovetoRel.instance.y_Setter_(unwrap_jso(this), value);
  
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


  @Deprecated("Internal Use Only")
  static PatternElement internalCreatePatternElement() {
    return new PatternElement._internalWrap();
  }

  external factory PatternElement._internalWrap();

  @Deprecated("Internal Use Only")
  PatternElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  PatternElement.created() : super.created();

  @DomName('SVGPatternElement.height')
  @DocsEditable()
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGPatternElement.instance.height_Getter_(unwrap_jso(this)));
  
  @DomName('SVGPatternElement.patternContentUnits')
  @DocsEditable()
  AnimatedEnumeration get patternContentUnits => wrap_jso(_blink.BlinkSVGPatternElement.instance.patternContentUnits_Getter_(unwrap_jso(this)));
  
  @DomName('SVGPatternElement.patternTransform')
  @DocsEditable()
  AnimatedTransformList get patternTransform => wrap_jso(_blink.BlinkSVGPatternElement.instance.patternTransform_Getter_(unwrap_jso(this)));
  
  @DomName('SVGPatternElement.patternUnits')
  @DocsEditable()
  AnimatedEnumeration get patternUnits => wrap_jso(_blink.BlinkSVGPatternElement.instance.patternUnits_Getter_(unwrap_jso(this)));
  
  @DomName('SVGPatternElement.width')
  @DocsEditable()
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGPatternElement.instance.width_Getter_(unwrap_jso(this)));
  
  @DomName('SVGPatternElement.x')
  @DocsEditable()
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGPatternElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGPatternElement.y')
  @DocsEditable()
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGPatternElement.instance.y_Getter_(unwrap_jso(this)));
  
  @DomName('SVGPatternElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio => wrap_jso(_blink.BlinkSVGPatternElement.instance.preserveAspectRatio_Getter_(unwrap_jso(this)));
  
  @DomName('SVGPatternElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox => wrap_jso(_blink.BlinkSVGPatternElement.instance.viewBox_Getter_(unwrap_jso(this)));
  
  @DomName('SVGPatternElement.requiredExtensions')
  @DocsEditable()
  StringList get requiredExtensions => wrap_jso(_blink.BlinkSVGPatternElement.instance.requiredExtensions_Getter_(unwrap_jso(this)));
  
  @DomName('SVGPatternElement.requiredFeatures')
  @DocsEditable()
  StringList get requiredFeatures => wrap_jso(_blink.BlinkSVGPatternElement.instance.requiredFeatures_Getter_(unwrap_jso(this)));
  
  @DomName('SVGPatternElement.systemLanguage')
  @DocsEditable()
  StringList get systemLanguage => wrap_jso(_blink.BlinkSVGPatternElement.instance.systemLanguage_Getter_(unwrap_jso(this)));
  
  @DomName('SVGPatternElement.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) => _blink.BlinkSVGPatternElement.instance.hasExtension_Callback_1_(unwrap_jso(this), extension);
  
  @DomName('SVGPatternElement.href')
  @DocsEditable()
  AnimatedString get href => wrap_jso(_blink.BlinkSVGPatternElement.instance.href_Getter_(unwrap_jso(this)));
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPoint')
@Unstable()
class Point extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory Point._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static Point internalCreatePoint() {
    return new Point._internalWrap();
  }

  factory Point._internalWrap() {
    return new Point.internal_();
  }

  @Deprecated("Internal Use Only")
  Point.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SVGPoint.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPoint.instance.x_Getter_(unwrap_jso(this));
  
  @DomName('SVGPoint.x')
  @DocsEditable()
  set x(num value) => _blink.BlinkSVGPoint.instance.x_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPoint.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPoint.instance.y_Getter_(unwrap_jso(this));
  
  @DomName('SVGPoint.y')
  @DocsEditable()
  set y(num value) => _blink.BlinkSVGPoint.instance.y_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPoint.matrixTransform')
  @DocsEditable()
  Point matrixTransform(Matrix matrix) => wrap_jso(_blink.BlinkSVGPoint.instance.matrixTransform_Callback_1_(unwrap_jso(this), unwrap_jso(matrix)));
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPointList')
@Unstable()
class PointList extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory PointList._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static PointList internalCreatePointList() {
    return new PointList._internalWrap();
  }

  factory PointList._internalWrap() {
    return new PointList.internal_();
  }

  @Deprecated("Internal Use Only")
  PointList.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SVGPointList.length')
  @DocsEditable()
  @Experimental() // untriaged
  int get length => _blink.BlinkSVGPointList.instance.length_Getter_(unwrap_jso(this));
  
  @DomName('SVGPointList.numberOfItems')
  @DocsEditable()
  int get numberOfItems => _blink.BlinkSVGPointList.instance.numberOfItems_Getter_(unwrap_jso(this));
  
  @DomName('SVGPointList.__setter__')
  @DocsEditable()
  @Experimental() // untriaged
  void __setter__(int index, Point newItem) => _blink.BlinkSVGPointList.instance.$__setter___Callback_2_(unwrap_jso(this), index, unwrap_jso(newItem));
  
  @DomName('SVGPointList.appendItem')
  @DocsEditable()
  Point appendItem(Point newItem) => wrap_jso(_blink.BlinkSVGPointList.instance.appendItem_Callback_1_(unwrap_jso(this), unwrap_jso(newItem)));
  
  @DomName('SVGPointList.clear')
  @DocsEditable()
  void clear() => _blink.BlinkSVGPointList.instance.clear_Callback_0_(unwrap_jso(this));
  
  @DomName('SVGPointList.getItem')
  @DocsEditable()
  Point getItem(int index) => wrap_jso(_blink.BlinkSVGPointList.instance.getItem_Callback_1_(unwrap_jso(this), index));
  
  @DomName('SVGPointList.initialize')
  @DocsEditable()
  Point initialize(Point newItem) => wrap_jso(_blink.BlinkSVGPointList.instance.initialize_Callback_1_(unwrap_jso(this), unwrap_jso(newItem)));
  
  @DomName('SVGPointList.insertItemBefore')
  @DocsEditable()
  Point insertItemBefore(Point newItem, int index) => wrap_jso(_blink.BlinkSVGPointList.instance.insertItemBefore_Callback_2_(unwrap_jso(this), unwrap_jso(newItem), index));
  
  @DomName('SVGPointList.removeItem')
  @DocsEditable()
  Point removeItem(int index) => wrap_jso(_blink.BlinkSVGPointList.instance.removeItem_Callback_1_(unwrap_jso(this), index));
  
  @DomName('SVGPointList.replaceItem')
  @DocsEditable()
  Point replaceItem(Point newItem, int index) => wrap_jso(_blink.BlinkSVGPointList.instance.replaceItem_Callback_2_(unwrap_jso(this), unwrap_jso(newItem), index));
  
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


  @Deprecated("Internal Use Only")
  static PolygonElement internalCreatePolygonElement() {
    return new PolygonElement._internalWrap();
  }

  external factory PolygonElement._internalWrap();

  @Deprecated("Internal Use Only")
  PolygonElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  PolygonElement.created() : super.created();

  @DomName('SVGPolygonElement.animatedPoints')
  @DocsEditable()
  PointList get animatedPoints => wrap_jso(_blink.BlinkSVGPolygonElement.instance.animatedPoints_Getter_(unwrap_jso(this)));
  
  @DomName('SVGPolygonElement.points')
  @DocsEditable()
  PointList get points => wrap_jso(_blink.BlinkSVGPolygonElement.instance.points_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static PolylineElement internalCreatePolylineElement() {
    return new PolylineElement._internalWrap();
  }

  external factory PolylineElement._internalWrap();

  @Deprecated("Internal Use Only")
  PolylineElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  PolylineElement.created() : super.created();

  @DomName('SVGPolylineElement.animatedPoints')
  @DocsEditable()
  PointList get animatedPoints => wrap_jso(_blink.BlinkSVGPolylineElement.instance.animatedPoints_Getter_(unwrap_jso(this)));
  
  @DomName('SVGPolylineElement.points')
  @DocsEditable()
  PointList get points => wrap_jso(_blink.BlinkSVGPolylineElement.instance.points_Getter_(unwrap_jso(this)));
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPreserveAspectRatio')
@Unstable()
class PreserveAspectRatio extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory PreserveAspectRatio._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static PreserveAspectRatio internalCreatePreserveAspectRatio() {
    return new PreserveAspectRatio._internalWrap();
  }

  factory PreserveAspectRatio._internalWrap() {
    return new PreserveAspectRatio.internal_();
  }

  @Deprecated("Internal Use Only")
  PreserveAspectRatio.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

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
  int get align => _blink.BlinkSVGPreserveAspectRatio.instance.align_Getter_(unwrap_jso(this));
  
  @DomName('SVGPreserveAspectRatio.align')
  @DocsEditable()
  set align(int value) => _blink.BlinkSVGPreserveAspectRatio.instance.align_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGPreserveAspectRatio.meetOrSlice')
  @DocsEditable()
  int get meetOrSlice => _blink.BlinkSVGPreserveAspectRatio.instance.meetOrSlice_Getter_(unwrap_jso(this));
  
  @DomName('SVGPreserveAspectRatio.meetOrSlice')
  @DocsEditable()
  set meetOrSlice(int value) => _blink.BlinkSVGPreserveAspectRatio.instance.meetOrSlice_Setter_(unwrap_jso(this), value);
  
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


  @Deprecated("Internal Use Only")
  static RadialGradientElement internalCreateRadialGradientElement() {
    return new RadialGradientElement._internalWrap();
  }

  external factory RadialGradientElement._internalWrap();

  @Deprecated("Internal Use Only")
  RadialGradientElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  RadialGradientElement.created() : super.created();

  @DomName('SVGRadialGradientElement.cx')
  @DocsEditable()
  AnimatedLength get cx => wrap_jso(_blink.BlinkSVGRadialGradientElement.instance.cx_Getter_(unwrap_jso(this)));
  
  @DomName('SVGRadialGradientElement.cy')
  @DocsEditable()
  AnimatedLength get cy => wrap_jso(_blink.BlinkSVGRadialGradientElement.instance.cy_Getter_(unwrap_jso(this)));
  
  @DomName('SVGRadialGradientElement.fr')
  @DocsEditable()
  AnimatedLength get fr => wrap_jso(_blink.BlinkSVGRadialGradientElement.instance.fr_Getter_(unwrap_jso(this)));
  
  @DomName('SVGRadialGradientElement.fx')
  @DocsEditable()
  AnimatedLength get fx => wrap_jso(_blink.BlinkSVGRadialGradientElement.instance.fx_Getter_(unwrap_jso(this)));
  
  @DomName('SVGRadialGradientElement.fy')
  @DocsEditable()
  AnimatedLength get fy => wrap_jso(_blink.BlinkSVGRadialGradientElement.instance.fy_Getter_(unwrap_jso(this)));
  
  @DomName('SVGRadialGradientElement.r')
  @DocsEditable()
  AnimatedLength get r => wrap_jso(_blink.BlinkSVGRadialGradientElement.instance.r_Getter_(unwrap_jso(this)));
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGRect')
@Unstable()
class Rect extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory Rect._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static Rect internalCreateRect() {
    return new Rect._internalWrap();
  }

  factory Rect._internalWrap() {
    return new Rect.internal_();
  }

  @Deprecated("Internal Use Only")
  Rect.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SVGRect.height')
  @DocsEditable()
  num get height => _blink.BlinkSVGRect.instance.height_Getter_(unwrap_jso(this));
  
  @DomName('SVGRect.height')
  @DocsEditable()
  set height(num value) => _blink.BlinkSVGRect.instance.height_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGRect.width')
  @DocsEditable()
  num get width => _blink.BlinkSVGRect.instance.width_Getter_(unwrap_jso(this));
  
  @DomName('SVGRect.width')
  @DocsEditable()
  set width(num value) => _blink.BlinkSVGRect.instance.width_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGRect.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGRect.instance.x_Getter_(unwrap_jso(this));
  
  @DomName('SVGRect.x')
  @DocsEditable()
  set x(num value) => _blink.BlinkSVGRect.instance.x_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGRect.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGRect.instance.y_Getter_(unwrap_jso(this));
  
  @DomName('SVGRect.y')
  @DocsEditable()
  set y(num value) => _blink.BlinkSVGRect.instance.y_Setter_(unwrap_jso(this), value);
  
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


  @Deprecated("Internal Use Only")
  static RectElement internalCreateRectElement() {
    return new RectElement._internalWrap();
  }

  external factory RectElement._internalWrap();

  @Deprecated("Internal Use Only")
  RectElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  RectElement.created() : super.created();

  @DomName('SVGRectElement.height')
  @DocsEditable()
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGRectElement.instance.height_Getter_(unwrap_jso(this)));
  
  @DomName('SVGRectElement.rx')
  @DocsEditable()
  AnimatedLength get rx => wrap_jso(_blink.BlinkSVGRectElement.instance.rx_Getter_(unwrap_jso(this)));
  
  @DomName('SVGRectElement.ry')
  @DocsEditable()
  AnimatedLength get ry => wrap_jso(_blink.BlinkSVGRectElement.instance.ry_Getter_(unwrap_jso(this)));
  
  @DomName('SVGRectElement.width')
  @DocsEditable()
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGRectElement.instance.width_Getter_(unwrap_jso(this)));
  
  @DomName('SVGRectElement.x')
  @DocsEditable()
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGRectElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGRectElement.y')
  @DocsEditable()
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGRectElement.instance.y_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static ScriptElement internalCreateScriptElement() {
    return new ScriptElement._internalWrap();
  }

  external factory ScriptElement._internalWrap();

  @Deprecated("Internal Use Only")
  ScriptElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  ScriptElement.created() : super.created();

  @DomName('SVGScriptElement.type')
  @DocsEditable()
  String get type => _blink.BlinkSVGScriptElement.instance.type_Getter_(unwrap_jso(this));
  
  @DomName('SVGScriptElement.type')
  @DocsEditable()
  set type(String value) => _blink.BlinkSVGScriptElement.instance.type_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGScriptElement.href')
  @DocsEditable()
  AnimatedString get href => wrap_jso(_blink.BlinkSVGScriptElement.instance.href_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static SetElement internalCreateSetElement() {
    return new SetElement._internalWrap();
  }

  external factory SetElement._internalWrap();

  @Deprecated("Internal Use Only")
  SetElement.internal_() : super.internal_();

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


  @Deprecated("Internal Use Only")
  static StopElement internalCreateStopElement() {
    return new StopElement._internalWrap();
  }

  external factory StopElement._internalWrap();

  @Deprecated("Internal Use Only")
  StopElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  StopElement.created() : super.created();

  @DomName('SVGStopElement.offset')
  @DocsEditable()
  AnimatedNumber get gradientOffset => wrap_jso(_blink.BlinkSVGStopElement.instance.offset_Getter_(unwrap_jso(this)));
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGStringList')
@Unstable()
class StringList extends DartHtmlDomObject with ListMixin<String>, ImmutableListMixin<String> implements List<String> {
  // To suppress missing implicit constructor warnings.
  factory StringList._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static StringList internalCreateStringList() {
    return new StringList._internalWrap();
  }

  factory StringList._internalWrap() {
    return new StringList.internal_();
  }

  @Deprecated("Internal Use Only")
  StringList.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SVGStringList.length')
  @DocsEditable()
  @Experimental() // untriaged
  int get length => _blink.BlinkSVGStringList.instance.length_Getter_(unwrap_jso(this));
  
  @DomName('SVGStringList.numberOfItems')
  @DocsEditable()
  int get numberOfItems => _blink.BlinkSVGStringList.instance.numberOfItems_Getter_(unwrap_jso(this));
  
  String operator[](int index) {
    if (index < 0 || index >= length)
      throw new RangeError.index(index, this);
    return getItem(index);
  }

  void operator[]=(int index, String value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<String> mixins.
  // String is the element type.


  set length(int value) {
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

  @DomName('SVGStringList.__setter__')
  @DocsEditable()
  @Experimental() // untriaged
  void __setter__(int index, String newItem) => _blink.BlinkSVGStringList.instance.$__setter___Callback_2_(unwrap_jso(this), index, newItem);
  
  @DomName('SVGStringList.appendItem')
  @DocsEditable()
  String appendItem(String newItem) => _blink.BlinkSVGStringList.instance.appendItem_Callback_1_(unwrap_jso(this), newItem);
  
  @DomName('SVGStringList.clear')
  @DocsEditable()
  void clear() => _blink.BlinkSVGStringList.instance.clear_Callback_0_(unwrap_jso(this));
  
  @DomName('SVGStringList.getItem')
  @DocsEditable()
  String getItem(int index) => _blink.BlinkSVGStringList.instance.getItem_Callback_1_(unwrap_jso(this), index);
  
  @DomName('SVGStringList.initialize')
  @DocsEditable()
  String initialize(String newItem) => _blink.BlinkSVGStringList.instance.initialize_Callback_1_(unwrap_jso(this), newItem);
  
  @DomName('SVGStringList.insertItemBefore')
  @DocsEditable()
  String insertItemBefore(String item, int index) => _blink.BlinkSVGStringList.instance.insertItemBefore_Callback_2_(unwrap_jso(this), item, index);
  
  @DomName('SVGStringList.removeItem')
  @DocsEditable()
  String removeItem(int index) => _blink.BlinkSVGStringList.instance.removeItem_Callback_1_(unwrap_jso(this), index);
  
  @DomName('SVGStringList.replaceItem')
  @DocsEditable()
  String replaceItem(String newItem, int index) => _blink.BlinkSVGStringList.instance.replaceItem_Callback_2_(unwrap_jso(this), newItem, index);
  
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


  @Deprecated("Internal Use Only")
  static StyleElement internalCreateStyleElement() {
    return new StyleElement._internalWrap();
  }

  external factory StyleElement._internalWrap();

  @Deprecated("Internal Use Only")
  StyleElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  StyleElement.created() : super.created();

  @DomName('SVGStyleElement.disabled')
  @DocsEditable()
  bool get disabled => _blink.BlinkSVGStyleElement.instance.disabled_Getter_(unwrap_jso(this));
  
  @DomName('SVGStyleElement.disabled')
  @DocsEditable()
  set disabled(bool value) => _blink.BlinkSVGStyleElement.instance.disabled_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGStyleElement.media')
  @DocsEditable()
  String get media => _blink.BlinkSVGStyleElement.instance.media_Getter_(unwrap_jso(this));
  
  @DomName('SVGStyleElement.media')
  @DocsEditable()
  set media(String value) => _blink.BlinkSVGStyleElement.instance.media_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGStyleElement.sheet')
  @DocsEditable()
  @Experimental() // untriaged
  StyleSheet get sheet => wrap_jso(_blink.BlinkSVGStyleElement.instance.sheet_Getter_(unwrap_jso(this)));
  
  @DomName('SVGStyleElement.title')
  @DocsEditable()
  String get title => _blink.BlinkSVGStyleElement.instance.title_Getter_(unwrap_jso(this));
  
  @DomName('SVGStyleElement.title')
  @DocsEditable()
  set title(String value) => _blink.BlinkSVGStyleElement.instance.title_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGStyleElement.type')
  @DocsEditable()
  String get type => _blink.BlinkSVGStyleElement.instance.type_Getter_(unwrap_jso(this));
  
  @DomName('SVGStyleElement.type')
  @DocsEditable()
  set type(String value) => _blink.BlinkSVGStyleElement.instance.type_Setter_(unwrap_jso(this), value);
  
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

  CssClassSet get classes => new _AttributeClassSet(this);

  List<Element> get children => new FilteredElementList(this);

  set children(List<Element> value) {
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

  set innerHtml(String value) {
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
  void insertAdjacentHtml(String where, String text, {NodeValidator validator,
      NodeTreeSanitizer treeSanitizer}) {
    throw new UnsupportedError("Cannot invoke insertAdjacentHtml on SVG.");
  }

  @DomName('Element.insertAdjacentElement')
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

  set _svgClassName(AnimatedString value) =>
      _blink.BlinkSVGElement.instance.className_Setter_(unwrap_jso(this), unwrap_jso(value));

  String get className => _svgClassName.baseVal;

  // Unbelievable hack. We can't create an SvgAnimatedString, but we can get
  // the existing one and change its baseVal. Then we call the blink setter directly
  // TODO(alanknight): Handle suppressing the SVGAnimated<*> better
  set className(String s) {
    var oldClass = _svgClassName;
    oldClass.baseVal = s;
    _svgClassName = oldClass;
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


  @Deprecated("Internal Use Only")
  static SvgElement internalCreateSvgElement() {
    return new SvgElement._internalWrap();
  }

  external factory SvgElement._internalWrap();

  @Deprecated("Internal Use Only")
  SvgElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  SvgElement.created() : super.created();

  @DomName('SVGElement.className')
  @DocsEditable()
  @Experimental() // untriaged
  AnimatedString get _svgClassName => wrap_jso(_blink.BlinkSVGElement.instance.className_Getter_(unwrap_jso(this)));
  
  @DomName('SVGElement.ownerSVGElement')
  @DocsEditable()
  SvgSvgElement get ownerSvgElement => wrap_jso(_blink.BlinkSVGElement.instance.ownerSVGElement_Getter_(unwrap_jso(this)));
  
  @DomName('SVGElement.style')
  @DocsEditable()
  @Experimental() // untriaged
  CssStyleDeclaration get style => wrap_jso(_blink.BlinkSVGElement.instance.style_Getter_(unwrap_jso(this)));
  
  @DomName('SVGElement.tabIndex')
  @DocsEditable()
  @Experimental() // untriaged
  int get tabIndex => _blink.BlinkSVGElement.instance.tabIndex_Getter_(unwrap_jso(this));
  
  @DomName('SVGElement.tabIndex')
  @DocsEditable()
  @Experimental() // untriaged
  set tabIndex(int value) => _blink.BlinkSVGElement.instance.tabIndex_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGElement.viewportElement')
  @DocsEditable()
  SvgElement get viewportElement => wrap_jso(_blink.BlinkSVGElement.instance.viewportElement_Getter_(unwrap_jso(this)));
  
  @DomName('SVGElement.blur')
  @DocsEditable()
  @Experimental() // untriaged
  void blur() => _blink.BlinkSVGElement.instance.blur_Callback_0_(unwrap_jso(this));
  
  @DomName('SVGElement.focus')
  @DocsEditable()
  @Experimental() // untriaged
  void focus() => _blink.BlinkSVGElement.instance.focus_Callback_0_(unwrap_jso(this));
  
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


  @Deprecated("Internal Use Only")
  static SvgSvgElement internalCreateSvgSvgElement() {
    return new SvgSvgElement._internalWrap();
  }

  external factory SvgSvgElement._internalWrap();

  @Deprecated("Internal Use Only")
  SvgSvgElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  SvgSvgElement.created() : super.created();

  @DomName('SVGSVGElement.currentScale')
  @DocsEditable()
  num get currentScale => _blink.BlinkSVGSVGElement.instance.currentScale_Getter_(unwrap_jso(this));
  
  @DomName('SVGSVGElement.currentScale')
  @DocsEditable()
  set currentScale(num value) => _blink.BlinkSVGSVGElement.instance.currentScale_Setter_(unwrap_jso(this), value);
  
  @DomName('SVGSVGElement.currentTranslate')
  @DocsEditable()
  Point get currentTranslate => wrap_jso(_blink.BlinkSVGSVGElement.instance.currentTranslate_Getter_(unwrap_jso(this)));
  
  @DomName('SVGSVGElement.currentView')
  @DocsEditable()
  ViewSpec get currentView => wrap_jso(_blink.BlinkSVGSVGElement.instance.currentView_Getter_(unwrap_jso(this)));
  
  @DomName('SVGSVGElement.height')
  @DocsEditable()
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGSVGElement.instance.height_Getter_(unwrap_jso(this)));
  
  @DomName('SVGSVGElement.pixelUnitToMillimeterX')
  @DocsEditable()
  num get pixelUnitToMillimeterX => _blink.BlinkSVGSVGElement.instance.pixelUnitToMillimeterX_Getter_(unwrap_jso(this));
  
  @DomName('SVGSVGElement.pixelUnitToMillimeterY')
  @DocsEditable()
  num get pixelUnitToMillimeterY => _blink.BlinkSVGSVGElement.instance.pixelUnitToMillimeterY_Getter_(unwrap_jso(this));
  
  @DomName('SVGSVGElement.screenPixelToMillimeterX')
  @DocsEditable()
  num get screenPixelToMillimeterX => _blink.BlinkSVGSVGElement.instance.screenPixelToMillimeterX_Getter_(unwrap_jso(this));
  
  @DomName('SVGSVGElement.screenPixelToMillimeterY')
  @DocsEditable()
  num get screenPixelToMillimeterY => _blink.BlinkSVGSVGElement.instance.screenPixelToMillimeterY_Getter_(unwrap_jso(this));
  
  @DomName('SVGSVGElement.useCurrentView')
  @DocsEditable()
  bool get useCurrentView => _blink.BlinkSVGSVGElement.instance.useCurrentView_Getter_(unwrap_jso(this));
  
  @DomName('SVGSVGElement.viewport')
  @DocsEditable()
  Rect get viewport => wrap_jso(_blink.BlinkSVGSVGElement.instance.viewport_Getter_(unwrap_jso(this)));
  
  @DomName('SVGSVGElement.width')
  @DocsEditable()
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGSVGElement.instance.width_Getter_(unwrap_jso(this)));
  
  @DomName('SVGSVGElement.x')
  @DocsEditable()
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGSVGElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGSVGElement.y')
  @DocsEditable()
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGSVGElement.instance.y_Getter_(unwrap_jso(this)));
  
  @DomName('SVGSVGElement.animationsPaused')
  @DocsEditable()
  bool animationsPaused() => _blink.BlinkSVGSVGElement.instance.animationsPaused_Callback_0_(unwrap_jso(this));
  
  @DomName('SVGSVGElement.checkEnclosure')
  @DocsEditable()
  bool checkEnclosure(SvgElement element, Rect rect) => _blink.BlinkSVGSVGElement.instance.checkEnclosure_Callback_2_(unwrap_jso(this), unwrap_jso(element), unwrap_jso(rect));
  
  @DomName('SVGSVGElement.checkIntersection')
  @DocsEditable()
  bool checkIntersection(SvgElement element, Rect rect) => _blink.BlinkSVGSVGElement.instance.checkIntersection_Callback_2_(unwrap_jso(this), unwrap_jso(element), unwrap_jso(rect));
  
  @DomName('SVGSVGElement.createSVGAngle')
  @DocsEditable()
  Angle createSvgAngle() => wrap_jso(_blink.BlinkSVGSVGElement.instance.createSVGAngle_Callback_0_(unwrap_jso(this)));
  
  @DomName('SVGSVGElement.createSVGLength')
  @DocsEditable()
  Length createSvgLength() => wrap_jso(_blink.BlinkSVGSVGElement.instance.createSVGLength_Callback_0_(unwrap_jso(this)));
  
  @DomName('SVGSVGElement.createSVGMatrix')
  @DocsEditable()
  Matrix createSvgMatrix() => wrap_jso(_blink.BlinkSVGSVGElement.instance.createSVGMatrix_Callback_0_(unwrap_jso(this)));
  
  @DomName('SVGSVGElement.createSVGNumber')
  @DocsEditable()
  Number createSvgNumber() => wrap_jso(_blink.BlinkSVGSVGElement.instance.createSVGNumber_Callback_0_(unwrap_jso(this)));
  
  @DomName('SVGSVGElement.createSVGPoint')
  @DocsEditable()
  Point createSvgPoint() => wrap_jso(_blink.BlinkSVGSVGElement.instance.createSVGPoint_Callback_0_(unwrap_jso(this)));
  
  @DomName('SVGSVGElement.createSVGRect')
  @DocsEditable()
  Rect createSvgRect() => wrap_jso(_blink.BlinkSVGSVGElement.instance.createSVGRect_Callback_0_(unwrap_jso(this)));
  
  @DomName('SVGSVGElement.createSVGTransform')
  @DocsEditable()
  Transform createSvgTransform() => wrap_jso(_blink.BlinkSVGSVGElement.instance.createSVGTransform_Callback_0_(unwrap_jso(this)));
  
  @DomName('SVGSVGElement.createSVGTransformFromMatrix')
  @DocsEditable()
  Transform createSvgTransformFromMatrix(Matrix matrix) => wrap_jso(_blink.BlinkSVGSVGElement.instance.createSVGTransformFromMatrix_Callback_1_(unwrap_jso(this), unwrap_jso(matrix)));
  
  @DomName('SVGSVGElement.deselectAll')
  @DocsEditable()
  void deselectAll() => _blink.BlinkSVGSVGElement.instance.deselectAll_Callback_0_(unwrap_jso(this));
  
  @DomName('SVGSVGElement.forceRedraw')
  @DocsEditable()
  void forceRedraw() => _blink.BlinkSVGSVGElement.instance.forceRedraw_Callback_0_(unwrap_jso(this));
  
  @DomName('SVGSVGElement.getCurrentTime')
  @DocsEditable()
  num getCurrentTime() => _blink.BlinkSVGSVGElement.instance.getCurrentTime_Callback_0_(unwrap_jso(this));
  
  @DomName('SVGSVGElement.getElementById')
  @DocsEditable()
  Element getElementById(String elementId) => wrap_jso(_blink.BlinkSVGSVGElement.instance.getElementById_Callback_1_(unwrap_jso(this), elementId));
  
  @DomName('SVGSVGElement.getEnclosureList')
  @DocsEditable()
  List<Node> getEnclosureList(Rect rect, SvgElement referenceElement) => wrap_jso(_blink.BlinkSVGSVGElement.instance.getEnclosureList_Callback_2_(unwrap_jso(this), unwrap_jso(rect), unwrap_jso(referenceElement)));
  
  @DomName('SVGSVGElement.getIntersectionList')
  @DocsEditable()
  List<Node> getIntersectionList(Rect rect, SvgElement referenceElement) => wrap_jso(_blink.BlinkSVGSVGElement.instance.getIntersectionList_Callback_2_(unwrap_jso(this), unwrap_jso(rect), unwrap_jso(referenceElement)));
  
  @DomName('SVGSVGElement.pauseAnimations')
  @DocsEditable()
  void pauseAnimations() => _blink.BlinkSVGSVGElement.instance.pauseAnimations_Callback_0_(unwrap_jso(this));
  
  @DomName('SVGSVGElement.setCurrentTime')
  @DocsEditable()
  void setCurrentTime(num seconds) => _blink.BlinkSVGSVGElement.instance.setCurrentTime_Callback_1_(unwrap_jso(this), seconds);
  
  @DomName('SVGSVGElement.suspendRedraw')
  @DocsEditable()
  int suspendRedraw(int maxWaitMilliseconds) => _blink.BlinkSVGSVGElement.instance.suspendRedraw_Callback_1_(unwrap_jso(this), maxWaitMilliseconds);
  
  @DomName('SVGSVGElement.unpauseAnimations')
  @DocsEditable()
  void unpauseAnimations() => _blink.BlinkSVGSVGElement.instance.unpauseAnimations_Callback_0_(unwrap_jso(this));
  
  @DomName('SVGSVGElement.unsuspendRedraw')
  @DocsEditable()
  void unsuspendRedraw(int suspendHandleId) => _blink.BlinkSVGSVGElement.instance.unsuspendRedraw_Callback_1_(unwrap_jso(this), suspendHandleId);
  
  @DomName('SVGSVGElement.unsuspendRedrawAll')
  @DocsEditable()
  void unsuspendRedrawAll() => _blink.BlinkSVGSVGElement.instance.unsuspendRedrawAll_Callback_0_(unwrap_jso(this));
  
  @DomName('SVGSVGElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio => wrap_jso(_blink.BlinkSVGSVGElement.instance.preserveAspectRatio_Getter_(unwrap_jso(this)));
  
  @DomName('SVGSVGElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox => wrap_jso(_blink.BlinkSVGSVGElement.instance.viewBox_Getter_(unwrap_jso(this)));
  
  @DomName('SVGSVGElement.zoomAndPan')
  @DocsEditable()
  int get zoomAndPan => _blink.BlinkSVGSVGElement.instance.zoomAndPan_Getter_(unwrap_jso(this));
  
  @DomName('SVGSVGElement.zoomAndPan')
  @DocsEditable()
  set zoomAndPan(int value) => _blink.BlinkSVGSVGElement.instance.zoomAndPan_Setter_(unwrap_jso(this), value);
  
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


  @Deprecated("Internal Use Only")
  static SwitchElement internalCreateSwitchElement() {
    return new SwitchElement._internalWrap();
  }

  external factory SwitchElement._internalWrap();

  @Deprecated("Internal Use Only")
  SwitchElement.internal_() : super.internal_();

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


  @Deprecated("Internal Use Only")
  static SymbolElement internalCreateSymbolElement() {
    return new SymbolElement._internalWrap();
  }

  external factory SymbolElement._internalWrap();

  @Deprecated("Internal Use Only")
  SymbolElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  SymbolElement.created() : super.created();

  @DomName('SVGSymbolElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio => wrap_jso(_blink.BlinkSVGSymbolElement.instance.preserveAspectRatio_Getter_(unwrap_jso(this)));
  
  @DomName('SVGSymbolElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox => wrap_jso(_blink.BlinkSVGSymbolElement.instance.viewBox_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static TSpanElement internalCreateTSpanElement() {
    return new TSpanElement._internalWrap();
  }

  external factory TSpanElement._internalWrap();

  @Deprecated("Internal Use Only")
  TSpanElement.internal_() : super.internal_();

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
abstract class Tests extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory Tests._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGTests.requiredExtensions')
  @DocsEditable()
  StringList get requiredExtensions;

  @DomName('SVGTests.requiredFeatures')
  @DocsEditable()
  StringList get requiredFeatures;

  @DomName('SVGTests.systemLanguage')
  @DocsEditable()
  StringList get systemLanguage;

  @DomName('SVGTests.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension);

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


  @Deprecated("Internal Use Only")
  static TextContentElement internalCreateTextContentElement() {
    return new TextContentElement._internalWrap();
  }

  external factory TextContentElement._internalWrap();

  @Deprecated("Internal Use Only")
  TextContentElement.internal_() : super.internal_();

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
  AnimatedEnumeration get lengthAdjust => wrap_jso(_blink.BlinkSVGTextContentElement.instance.lengthAdjust_Getter_(unwrap_jso(this)));
  
  @DomName('SVGTextContentElement.textLength')
  @DocsEditable()
  AnimatedLength get textLength => wrap_jso(_blink.BlinkSVGTextContentElement.instance.textLength_Getter_(unwrap_jso(this)));
  
  @DomName('SVGTextContentElement.getCharNumAtPosition')
  @DocsEditable()
  int getCharNumAtPosition(Point point) => _blink.BlinkSVGTextContentElement.instance.getCharNumAtPosition_Callback_1_(unwrap_jso(this), unwrap_jso(point));
  
  @DomName('SVGTextContentElement.getComputedTextLength')
  @DocsEditable()
  num getComputedTextLength() => _blink.BlinkSVGTextContentElement.instance.getComputedTextLength_Callback_0_(unwrap_jso(this));
  
  @DomName('SVGTextContentElement.getEndPositionOfChar')
  @DocsEditable()
  Point getEndPositionOfChar(int charnum) => wrap_jso(_blink.BlinkSVGTextContentElement.instance.getEndPositionOfChar_Callback_1_(unwrap_jso(this), charnum));
  
  @DomName('SVGTextContentElement.getExtentOfChar')
  @DocsEditable()
  Rect getExtentOfChar(int charnum) => wrap_jso(_blink.BlinkSVGTextContentElement.instance.getExtentOfChar_Callback_1_(unwrap_jso(this), charnum));
  
  @DomName('SVGTextContentElement.getNumberOfChars')
  @DocsEditable()
  int getNumberOfChars() => _blink.BlinkSVGTextContentElement.instance.getNumberOfChars_Callback_0_(unwrap_jso(this));
  
  @DomName('SVGTextContentElement.getRotationOfChar')
  @DocsEditable()
  num getRotationOfChar(int charnum) => _blink.BlinkSVGTextContentElement.instance.getRotationOfChar_Callback_1_(unwrap_jso(this), charnum);
  
  @DomName('SVGTextContentElement.getStartPositionOfChar')
  @DocsEditable()
  Point getStartPositionOfChar(int charnum) => wrap_jso(_blink.BlinkSVGTextContentElement.instance.getStartPositionOfChar_Callback_1_(unwrap_jso(this), charnum));
  
  @DomName('SVGTextContentElement.getSubStringLength')
  @DocsEditable()
  num getSubStringLength(int charnum, int nchars) => _blink.BlinkSVGTextContentElement.instance.getSubStringLength_Callback_2_(unwrap_jso(this), charnum, nchars);
  
  @DomName('SVGTextContentElement.selectSubString')
  @DocsEditable()
  void selectSubString(int charnum, int nchars) => _blink.BlinkSVGTextContentElement.instance.selectSubString_Callback_2_(unwrap_jso(this), charnum, nchars);
  
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


  @Deprecated("Internal Use Only")
  static TextElement internalCreateTextElement() {
    return new TextElement._internalWrap();
  }

  external factory TextElement._internalWrap();

  @Deprecated("Internal Use Only")
  TextElement.internal_() : super.internal_();

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


  @Deprecated("Internal Use Only")
  static TextPathElement internalCreateTextPathElement() {
    return new TextPathElement._internalWrap();
  }

  external factory TextPathElement._internalWrap();

  @Deprecated("Internal Use Only")
  TextPathElement.internal_() : super.internal_();

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
  AnimatedEnumeration get method => wrap_jso(_blink.BlinkSVGTextPathElement.instance.method_Getter_(unwrap_jso(this)));
  
  @DomName('SVGTextPathElement.spacing')
  @DocsEditable()
  AnimatedEnumeration get spacing => wrap_jso(_blink.BlinkSVGTextPathElement.instance.spacing_Getter_(unwrap_jso(this)));
  
  @DomName('SVGTextPathElement.startOffset')
  @DocsEditable()
  AnimatedLength get startOffset => wrap_jso(_blink.BlinkSVGTextPathElement.instance.startOffset_Getter_(unwrap_jso(this)));
  
  @DomName('SVGTextPathElement.href')
  @DocsEditable()
  AnimatedString get href => wrap_jso(_blink.BlinkSVGTextPathElement.instance.href_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static TextPositioningElement internalCreateTextPositioningElement() {
    return new TextPositioningElement._internalWrap();
  }

  external factory TextPositioningElement._internalWrap();

  @Deprecated("Internal Use Only")
  TextPositioningElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  TextPositioningElement.created() : super.created();

  @DomName('SVGTextPositioningElement.dx')
  @DocsEditable()
  AnimatedLengthList get dx => wrap_jso(_blink.BlinkSVGTextPositioningElement.instance.dx_Getter_(unwrap_jso(this)));
  
  @DomName('SVGTextPositioningElement.dy')
  @DocsEditable()
  AnimatedLengthList get dy => wrap_jso(_blink.BlinkSVGTextPositioningElement.instance.dy_Getter_(unwrap_jso(this)));
  
  @DomName('SVGTextPositioningElement.rotate')
  @DocsEditable()
  AnimatedNumberList get rotate => wrap_jso(_blink.BlinkSVGTextPositioningElement.instance.rotate_Getter_(unwrap_jso(this)));
  
  @DomName('SVGTextPositioningElement.x')
  @DocsEditable()
  AnimatedLengthList get x => wrap_jso(_blink.BlinkSVGTextPositioningElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGTextPositioningElement.y')
  @DocsEditable()
  AnimatedLengthList get y => wrap_jso(_blink.BlinkSVGTextPositioningElement.instance.y_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static TitleElement internalCreateTitleElement() {
    return new TitleElement._internalWrap();
  }

  external factory TitleElement._internalWrap();

  @Deprecated("Internal Use Only")
  TitleElement.internal_() : super.internal_();

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
class Transform extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory Transform._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static Transform internalCreateTransform() {
    return new Transform._internalWrap();
  }

  factory Transform._internalWrap() {
    return new Transform.internal_();
  }

  @Deprecated("Internal Use Only")
  Transform.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

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
  num get angle => _blink.BlinkSVGTransform.instance.angle_Getter_(unwrap_jso(this));
  
  @DomName('SVGTransform.matrix')
  @DocsEditable()
  Matrix get matrix => wrap_jso(_blink.BlinkSVGTransform.instance.matrix_Getter_(unwrap_jso(this)));
  
  @DomName('SVGTransform.type')
  @DocsEditable()
  int get type => _blink.BlinkSVGTransform.instance.type_Getter_(unwrap_jso(this));
  
  @DomName('SVGTransform.setMatrix')
  @DocsEditable()
  void setMatrix(Matrix matrix) => _blink.BlinkSVGTransform.instance.setMatrix_Callback_1_(unwrap_jso(this), unwrap_jso(matrix));
  
  @DomName('SVGTransform.setRotate')
  @DocsEditable()
  void setRotate(num angle, num cx, num cy) => _blink.BlinkSVGTransform.instance.setRotate_Callback_3_(unwrap_jso(this), angle, cx, cy);
  
  @DomName('SVGTransform.setScale')
  @DocsEditable()
  void setScale(num sx, num sy) => _blink.BlinkSVGTransform.instance.setScale_Callback_2_(unwrap_jso(this), sx, sy);
  
  @DomName('SVGTransform.setSkewX')
  @DocsEditable()
  void setSkewX(num angle) => _blink.BlinkSVGTransform.instance.setSkewX_Callback_1_(unwrap_jso(this), angle);
  
  @DomName('SVGTransform.setSkewY')
  @DocsEditable()
  void setSkewY(num angle) => _blink.BlinkSVGTransform.instance.setSkewY_Callback_1_(unwrap_jso(this), angle);
  
  @DomName('SVGTransform.setTranslate')
  @DocsEditable()
  void setTranslate(num tx, num ty) => _blink.BlinkSVGTransform.instance.setTranslate_Callback_2_(unwrap_jso(this), tx, ty);
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGTransformList')
@Unstable()
class TransformList extends DartHtmlDomObject with ListMixin<Transform>, ImmutableListMixin<Transform> implements List<Transform> {
  // To suppress missing implicit constructor warnings.
  factory TransformList._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static TransformList internalCreateTransformList() {
    return new TransformList._internalWrap();
  }

  factory TransformList._internalWrap() {
    return new TransformList.internal_();
  }

  @Deprecated("Internal Use Only")
  TransformList.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SVGTransformList.length')
  @DocsEditable()
  @Experimental() // untriaged
  int get length => _blink.BlinkSVGTransformList.instance.length_Getter_(unwrap_jso(this));
  
  @DomName('SVGTransformList.numberOfItems')
  @DocsEditable()
  int get numberOfItems => _blink.BlinkSVGTransformList.instance.numberOfItems_Getter_(unwrap_jso(this));
  
  Transform operator[](int index) {
    if (index < 0 || index >= length)
      throw new RangeError.index(index, this);
    return getItem(index);
  }

  void operator[]=(int index, Transform value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Transform> mixins.
  // Transform is the element type.


  set length(int value) {
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

  @DomName('SVGTransformList.__setter__')
  @DocsEditable()
  @Experimental() // untriaged
  void __setter__(int index, Transform newItem) => _blink.BlinkSVGTransformList.instance.$__setter___Callback_2_(unwrap_jso(this), index, unwrap_jso(newItem));
  
  @DomName('SVGTransformList.appendItem')
  @DocsEditable()
  Transform appendItem(Transform newItem) => wrap_jso(_blink.BlinkSVGTransformList.instance.appendItem_Callback_1_(unwrap_jso(this), unwrap_jso(newItem)));
  
  @DomName('SVGTransformList.clear')
  @DocsEditable()
  void clear() => _blink.BlinkSVGTransformList.instance.clear_Callback_0_(unwrap_jso(this));
  
  @DomName('SVGTransformList.consolidate')
  @DocsEditable()
  Transform consolidate() => wrap_jso(_blink.BlinkSVGTransformList.instance.consolidate_Callback_0_(unwrap_jso(this)));
  
  @DomName('SVGTransformList.createSVGTransformFromMatrix')
  @DocsEditable()
  Transform createSvgTransformFromMatrix(Matrix matrix) => wrap_jso(_blink.BlinkSVGTransformList.instance.createSVGTransformFromMatrix_Callback_1_(unwrap_jso(this), unwrap_jso(matrix)));
  
  @DomName('SVGTransformList.getItem')
  @DocsEditable()
  Transform getItem(int index) => wrap_jso(_blink.BlinkSVGTransformList.instance.getItem_Callback_1_(unwrap_jso(this), index));
  
  @DomName('SVGTransformList.initialize')
  @DocsEditable()
  Transform initialize(Transform newItem) => wrap_jso(_blink.BlinkSVGTransformList.instance.initialize_Callback_1_(unwrap_jso(this), unwrap_jso(newItem)));
  
  @DomName('SVGTransformList.insertItemBefore')
  @DocsEditable()
  Transform insertItemBefore(Transform newItem, int index) => wrap_jso(_blink.BlinkSVGTransformList.instance.insertItemBefore_Callback_2_(unwrap_jso(this), unwrap_jso(newItem), index));
  
  @DomName('SVGTransformList.removeItem')
  @DocsEditable()
  Transform removeItem(int index) => wrap_jso(_blink.BlinkSVGTransformList.instance.removeItem_Callback_1_(unwrap_jso(this), index));
  
  @DomName('SVGTransformList.replaceItem')
  @DocsEditable()
  Transform replaceItem(Transform newItem, int index) => wrap_jso(_blink.BlinkSVGTransformList.instance.replaceItem_Callback_2_(unwrap_jso(this), unwrap_jso(newItem), index));
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGUnitTypes')
@Unstable()
class UnitTypes extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory UnitTypes._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static UnitTypes internalCreateUnitTypes() {
    return new UnitTypes._internalWrap();
  }

  factory UnitTypes._internalWrap() {
    return new UnitTypes.internal_();
  }

  @Deprecated("Internal Use Only")
  UnitTypes.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

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
abstract class UriReference extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory UriReference._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGURIReference.href')
  @DocsEditable()
  AnimatedString get href;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGUseElement')
@Unstable()
class UseElement extends GraphicsElement implements UriReference {
  // To suppress missing implicit constructor warnings.
  factory UseElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGUseElement.SVGUseElement')
  @DocsEditable()
  factory UseElement() => _SvgElementFactoryProvider.createSvgElement_tag("use");


  @Deprecated("Internal Use Only")
  static UseElement internalCreateUseElement() {
    return new UseElement._internalWrap();
  }

  external factory UseElement._internalWrap();

  @Deprecated("Internal Use Only")
  UseElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  UseElement.created() : super.created();

  @DomName('SVGUseElement.height')
  @DocsEditable()
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGUseElement.instance.height_Getter_(unwrap_jso(this)));
  
  @DomName('SVGUseElement.width')
  @DocsEditable()
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGUseElement.instance.width_Getter_(unwrap_jso(this)));
  
  @DomName('SVGUseElement.x')
  @DocsEditable()
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGUseElement.instance.x_Getter_(unwrap_jso(this)));
  
  @DomName('SVGUseElement.y')
  @DocsEditable()
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGUseElement.instance.y_Getter_(unwrap_jso(this)));
  
  @DomName('SVGUseElement.href')
  @DocsEditable()
  AnimatedString get href => wrap_jso(_blink.BlinkSVGUseElement.instance.href_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static ViewElement internalCreateViewElement() {
    return new ViewElement._internalWrap();
  }

  external factory ViewElement._internalWrap();

  @Deprecated("Internal Use Only")
  ViewElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  ViewElement.created() : super.created();

  @DomName('SVGViewElement.viewTarget')
  @DocsEditable()
  StringList get viewTarget => wrap_jso(_blink.BlinkSVGViewElement.instance.viewTarget_Getter_(unwrap_jso(this)));
  
  @DomName('SVGViewElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio => wrap_jso(_blink.BlinkSVGViewElement.instance.preserveAspectRatio_Getter_(unwrap_jso(this)));
  
  @DomName('SVGViewElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox => wrap_jso(_blink.BlinkSVGViewElement.instance.viewBox_Getter_(unwrap_jso(this)));
  
  @DomName('SVGViewElement.zoomAndPan')
  @DocsEditable()
  int get zoomAndPan => _blink.BlinkSVGViewElement.instance.zoomAndPan_Getter_(unwrap_jso(this));
  
  @DomName('SVGViewElement.zoomAndPan')
  @DocsEditable()
  set zoomAndPan(int value) => _blink.BlinkSVGViewElement.instance.zoomAndPan_Setter_(unwrap_jso(this), value);
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGViewSpec')
@Unstable()
class ViewSpec extends DartHtmlDomObject implements FitToViewBox, ZoomAndPan {
  // To suppress missing implicit constructor warnings.
  factory ViewSpec._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static ViewSpec internalCreateViewSpec() {
    return new ViewSpec._internalWrap();
  }

  factory ViewSpec._internalWrap() {
    return new ViewSpec.internal_();
  }

  @Deprecated("Internal Use Only")
  ViewSpec.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SVGViewSpec.preserveAspectRatioString')
  @DocsEditable()
  String get preserveAspectRatioString => _blink.BlinkSVGViewSpec.instance.preserveAspectRatioString_Getter_(unwrap_jso(this));
  
  @DomName('SVGViewSpec.transform')
  @DocsEditable()
  TransformList get transform => wrap_jso(_blink.BlinkSVGViewSpec.instance.transform_Getter_(unwrap_jso(this)));
  
  @DomName('SVGViewSpec.transformString')
  @DocsEditable()
  String get transformString => _blink.BlinkSVGViewSpec.instance.transformString_Getter_(unwrap_jso(this));
  
  @DomName('SVGViewSpec.viewBoxString')
  @DocsEditable()
  String get viewBoxString => _blink.BlinkSVGViewSpec.instance.viewBoxString_Getter_(unwrap_jso(this));
  
  @DomName('SVGViewSpec.viewTarget')
  @DocsEditable()
  SvgElement get viewTarget => wrap_jso(_blink.BlinkSVGViewSpec.instance.viewTarget_Getter_(unwrap_jso(this)));
  
  @DomName('SVGViewSpec.viewTargetString')
  @DocsEditable()
  String get viewTargetString => _blink.BlinkSVGViewSpec.instance.viewTargetString_Getter_(unwrap_jso(this));
  
  @DomName('SVGViewSpec.preserveAspectRatio')
  @DocsEditable()
  @Experimental() // nonstandard
  AnimatedPreserveAspectRatio get preserveAspectRatio => wrap_jso(_blink.BlinkSVGViewSpec.instance.preserveAspectRatio_Getter_(unwrap_jso(this)));
  
  @DomName('SVGViewSpec.viewBox')
  @DocsEditable()
  @Experimental() // nonstandard
  AnimatedRect get viewBox => wrap_jso(_blink.BlinkSVGViewSpec.instance.viewBox_Getter_(unwrap_jso(this)));
  
  @DomName('SVGViewSpec.zoomAndPan')
  @DocsEditable()
  @Experimental() // nonstandard
  int get zoomAndPan => _blink.BlinkSVGViewSpec.instance.zoomAndPan_Getter_(unwrap_jso(this));
  
  @DomName('SVGViewSpec.zoomAndPan')
  @DocsEditable()
  @Experimental() // nonstandard
  set zoomAndPan(int value) => _blink.BlinkSVGViewSpec.instance.zoomAndPan_Setter_(unwrap_jso(this), value);
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGZoomAndPan')
@Unstable()
abstract class ZoomAndPan extends DartHtmlDomObject {
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
  int get zoomAndPan;

  @DomName('SVGZoomAndPan.zoomAndPan')
  @DocsEditable()
  set zoomAndPan(int value);

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


  @Deprecated("Internal Use Only")
  static ZoomEvent internalCreateZoomEvent() {
    return new ZoomEvent._internalWrap();
  }

  external factory ZoomEvent._internalWrap();

  @Deprecated("Internal Use Only")
  ZoomEvent.internal_() : super.internal_();


  @DomName('SVGZoomEvent.newScale')
  @DocsEditable()
  num get newScale => _blink.BlinkSVGZoomEvent.instance.newScale_Getter_(unwrap_jso(this));
  
  @DomName('SVGZoomEvent.newTranslate')
  @DocsEditable()
  Point get newTranslate => wrap_jso(_blink.BlinkSVGZoomEvent.instance.newTranslate_Getter_(unwrap_jso(this)));
  
  @DomName('SVGZoomEvent.previousScale')
  @DocsEditable()
  num get previousScale => _blink.BlinkSVGZoomEvent.instance.previousScale_Getter_(unwrap_jso(this));
  
  @DomName('SVGZoomEvent.previousTranslate')
  @DocsEditable()
  Point get previousTranslate => wrap_jso(_blink.BlinkSVGZoomEvent.instance.previousTranslate_Getter_(unwrap_jso(this)));
  
  @DomName('SVGZoomEvent.zoomRectScreen')
  @DocsEditable()
  Rect get zoomRectScreen => wrap_jso(_blink.BlinkSVGZoomEvent.instance.zoomRectScreen_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static _GradientElement internalCreate_GradientElement() {
    return new _GradientElement._internalWrap();
  }

  external factory _GradientElement._internalWrap();

  @Deprecated("Internal Use Only")
  _GradientElement.internal_() : super.internal_();

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
  AnimatedTransformList get gradientTransform => wrap_jso(_blink.BlinkSVGGradientElement.instance.gradientTransform_Getter_(unwrap_jso(this)));
  
  @DomName('SVGGradientElement.gradientUnits')
  @DocsEditable()
  AnimatedEnumeration get gradientUnits => wrap_jso(_blink.BlinkSVGGradientElement.instance.gradientUnits_Getter_(unwrap_jso(this)));
  
  @DomName('SVGGradientElement.spreadMethod')
  @DocsEditable()
  AnimatedEnumeration get spreadMethod => wrap_jso(_blink.BlinkSVGGradientElement.instance.spreadMethod_Getter_(unwrap_jso(this)));
  
  @DomName('SVGGradientElement.href')
  @DocsEditable()
  AnimatedString get href => wrap_jso(_blink.BlinkSVGGradientElement.instance.href_Getter_(unwrap_jso(this)));
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGComponentTransferFunctionElement')
@Unstable()
class _SVGComponentTransferFunctionElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGComponentTransferFunctionElement._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static _SVGComponentTransferFunctionElement internalCreate_SVGComponentTransferFunctionElement() {
    return new _SVGComponentTransferFunctionElement._internalWrap();
  }

  external factory _SVGComponentTransferFunctionElement._internalWrap();

  @Deprecated("Internal Use Only")
  _SVGComponentTransferFunctionElement.internal_() : super.internal_();

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


@DocsEditable()
@DomName('SVGCursorElement')
@Unstable()
class _SVGCursorElement extends SvgElement implements UriReference, Tests {
  // To suppress missing implicit constructor warnings.
  factory _SVGCursorElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGCursorElement.SVGCursorElement')
  @DocsEditable()
  factory _SVGCursorElement() => _SvgElementFactoryProvider.createSvgElement_tag("cursor");


  @Deprecated("Internal Use Only")
  static _SVGCursorElement internalCreate_SVGCursorElement() {
    return new _SVGCursorElement._internalWrap();
  }

  external factory _SVGCursorElement._internalWrap();

  @Deprecated("Internal Use Only")
  _SVGCursorElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGCursorElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  // Override these methods for Dartium _SVGCursorElement can't be abstract.
  StringList get requiredExtensions => wrap_jso(_blink.BlinkSVGCursorElement.instance.requiredExtensions_Getter_(unwrap_jso(this)));
  StringList get requiredFeatures => wrap_jso(_blink.BlinkSVGCursorElement.instance.requiredFeatures_Getter_(unwrap_jso(this)));
  StringList get systemLanguage => wrap_jso(_blink.BlinkSVGCursorElement.instance.systemLanguage_Getter_(unwrap_jso(this)));
  AnimatedString get href => wrap_jso(_blink.BlinkSVGCursorElement.instance.href_Getter_(unwrap_jso(this)));
  bool hasExtension(String extension) => _blink.BlinkSVGCursorElement.instance.hasExtension_Callback_1_(unwrap_jso(this), extension);
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFEDropShadowElement')
@Experimental() // nonstandard
class _SVGFEDropShadowElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory _SVGFEDropShadowElement._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static _SVGFEDropShadowElement internalCreate_SVGFEDropShadowElement() {
    return new _SVGFEDropShadowElement._internalWrap();
  }

  external factory _SVGFEDropShadowElement._internalWrap();

  @Deprecated("Internal Use Only")
  _SVGFEDropShadowElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGFEDropShadowElement.created() : super.created();

  // Override these methods for Dartium _SVGFEDropShadowElement can't be abstract.
  AnimatedLength get height => wrap_jso(_blink.BlinkSVGFEDropShadowElement.instance.height_Getter_(unwrap_jso(this)));
  AnimatedString get result => wrap_jso(_blink.BlinkSVGFEDropShadowElement.instance.result_Getter_(unwrap_jso(this)));
  AnimatedLength get width => wrap_jso(_blink.BlinkSVGFEDropShadowElement.instance.width_Getter_(unwrap_jso(this)));
  AnimatedLength get x => wrap_jso(_blink.BlinkSVGFEDropShadowElement.instance.x_Getter_(unwrap_jso(this)));
  AnimatedLength get y => wrap_jso(_blink.BlinkSVGFEDropShadowElement.instance.y_Getter_(unwrap_jso(this)));
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGMPathElement')
class _SVGMPathElement extends SvgElement implements UriReference {
  // To suppress missing implicit constructor warnings.
  factory _SVGMPathElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGMPathElement.SVGMPathElement')
  @DocsEditable()
  factory _SVGMPathElement() => _SvgElementFactoryProvider.createSvgElement_tag("mpath");


  @Deprecated("Internal Use Only")
  static _SVGMPathElement internalCreate_SVGMPathElement() {
    return new _SVGMPathElement._internalWrap();
  }

  external factory _SVGMPathElement._internalWrap();

  @Deprecated("Internal Use Only")
  _SVGMPathElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGMPathElement.created() : super.created();

  // Override these methods for Dartium _SVGMPathElement can't be abstract.
  AnimatedString get href => wrap_jso(_blink.BlinkSVGMPathElement.instance.href_Getter_(unwrap_jso(this)));
}

