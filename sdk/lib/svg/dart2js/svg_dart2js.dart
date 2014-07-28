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
import 'dart:_internal' hide deprecated;
import 'dart:html';
import 'dart:html_common';
import 'dart:_js_helper' show Creates, Returns, JSName, Native;
import 'dart:_foreign_helper' show JS;
import 'dart:_interceptors' show Interceptor;
// DO NOT EDIT - unless you are editing documentation as per:
// https://code.google.com/p/dart/wiki/ContributingHTMLDocumentation
// Auto-generated dart:svg library.





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


@DocsEditable()
@DomName('SVGAElement')
@Unstable()
@Native("SVGAElement")
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
  final AnimatedString target;

  // From SVGURIReference

  @DomName('SVGAElement.href')
  @DocsEditable()
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGAltGlyphElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGAltGlyphElement")
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
  static bool get supported => SvgElement.isTagSupported('altGlyph') && (new SvgElement.tag('altGlyph') is AltGlyphElement);

  @DomName('SVGAltGlyphElement.format')
  @DocsEditable()
  String format;

  @DomName('SVGAltGlyphElement.glyphRef')
  @DocsEditable()
  String glyphRef;

  // From SVGURIReference

  @DomName('SVGAltGlyphElement.href')
  @DocsEditable()
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGAngle')
@Unstable()
@Native("SVGAngle")
class Angle extends Interceptor {
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
  final int unitType;

  @DomName('SVGAngle.value')
  @DocsEditable()
  num value;

  @DomName('SVGAngle.valueAsString')
  @DocsEditable()
  String valueAsString;

  @DomName('SVGAngle.valueInSpecifiedUnits')
  @DocsEditable()
  num valueInSpecifiedUnits;

  @DomName('SVGAngle.convertToSpecifiedUnits')
  @DocsEditable()
  void convertToSpecifiedUnits(int unitType) native;

  @DomName('SVGAngle.newValueSpecifiedUnits')
  @DocsEditable()
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGAnimateElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGAnimateElement")
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
  static bool get supported => SvgElement.isTagSupported('animate') && (new SvgElement.tag('animate') is AnimateElement);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGAnimateMotionElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGAnimateMotionElement")
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
  static bool get supported => SvgElement.isTagSupported('animateMotion') && (new SvgElement.tag('animateMotion') is AnimateMotionElement);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGAnimateTransformElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGAnimateTransformElement")
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
  static bool get supported => SvgElement.isTagSupported('animateTransform') && (new SvgElement.tag('animateTransform') is AnimateTransformElement);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGAnimatedAngle')
@Unstable()
@Native("SVGAnimatedAngle")
class AnimatedAngle extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AnimatedAngle._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedAngle.animVal')
  @DocsEditable()
  final Angle animVal;

  @DomName('SVGAnimatedAngle.baseVal')
  @DocsEditable()
  final Angle baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGAnimatedBoolean')
@Unstable()
@Native("SVGAnimatedBoolean")
class AnimatedBoolean extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AnimatedBoolean._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedBoolean.animVal')
  @DocsEditable()
  final bool animVal;

  @DomName('SVGAnimatedBoolean.baseVal')
  @DocsEditable()
  bool baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGAnimatedEnumeration')
@Unstable()
@Native("SVGAnimatedEnumeration")
class AnimatedEnumeration extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AnimatedEnumeration._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedEnumeration.animVal')
  @DocsEditable()
  final int animVal;

  @DomName('SVGAnimatedEnumeration.baseVal')
  @DocsEditable()
  int baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGAnimatedInteger')
@Unstable()
@Native("SVGAnimatedInteger")
class AnimatedInteger extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AnimatedInteger._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedInteger.animVal')
  @DocsEditable()
  final int animVal;

  @DomName('SVGAnimatedInteger.baseVal')
  @DocsEditable()
  int baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGAnimatedLength')
@Unstable()
@Native("SVGAnimatedLength")
class AnimatedLength extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AnimatedLength._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedLength.animVal')
  @DocsEditable()
  final Length animVal;

  @DomName('SVGAnimatedLength.baseVal')
  @DocsEditable()
  final Length baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGAnimatedLengthList')
@Unstable()
@Native("SVGAnimatedLengthList")
class AnimatedLengthList extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AnimatedLengthList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedLengthList.animVal')
  @DocsEditable()
  final LengthList animVal;

  @DomName('SVGAnimatedLengthList.baseVal')
  @DocsEditable()
  final LengthList baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGAnimatedNumber')
@Unstable()
@Native("SVGAnimatedNumber")
class AnimatedNumber extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AnimatedNumber._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedNumber.animVal')
  @DocsEditable()
  final double animVal;

  @DomName('SVGAnimatedNumber.baseVal')
  @DocsEditable()
  num baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGAnimatedNumberList')
@Unstable()
@Native("SVGAnimatedNumberList")
class AnimatedNumberList extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AnimatedNumberList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedNumberList.animVal')
  @DocsEditable()
  final NumberList animVal;

  @DomName('SVGAnimatedNumberList.baseVal')
  @DocsEditable()
  final NumberList baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGAnimatedPreserveAspectRatio')
@Unstable()
@Native("SVGAnimatedPreserveAspectRatio")
class AnimatedPreserveAspectRatio extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AnimatedPreserveAspectRatio._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedPreserveAspectRatio.animVal')
  @DocsEditable()
  final PreserveAspectRatio animVal;

  @DomName('SVGAnimatedPreserveAspectRatio.baseVal')
  @DocsEditable()
  final PreserveAspectRatio baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGAnimatedRect')
@Unstable()
@Native("SVGAnimatedRect")
class AnimatedRect extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AnimatedRect._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedRect.animVal')
  @DocsEditable()
  final Rect animVal;

  @DomName('SVGAnimatedRect.baseVal')
  @DocsEditable()
  final Rect baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGAnimatedString')
@Unstable()
@Native("SVGAnimatedString")
class AnimatedString extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AnimatedString._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedString.animVal')
  @DocsEditable()
  final String animVal;

  @DomName('SVGAnimatedString.baseVal')
  @DocsEditable()
  String baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGAnimatedTransformList')
@Unstable()
@Native("SVGAnimatedTransformList")
class AnimatedTransformList extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AnimatedTransformList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedTransformList.animVal')
  @DocsEditable()
  final TransformList animVal;

  @DomName('SVGAnimatedTransformList.baseVal')
  @DocsEditable()
  final TransformList baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGAnimationElement')
@Unstable()
@Native("SVGAnimationElement")
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
  final SvgElement targetElement;

  @DomName('SVGAnimationElement.beginElement')
  @DocsEditable()
  void beginElement() native;

  @DomName('SVGAnimationElement.beginElementAt')
  @DocsEditable()
  void beginElementAt(num offset) native;

  @DomName('SVGAnimationElement.endElement')
  @DocsEditable()
  void endElement() native;

  @DomName('SVGAnimationElement.endElementAt')
  @DocsEditable()
  void endElementAt(num offset) native;

  @DomName('SVGAnimationElement.getCurrentTime')
  @DocsEditable()
  double getCurrentTime() native;

  @DomName('SVGAnimationElement.getSimpleDuration')
  @DocsEditable()
  double getSimpleDuration() native;

  @DomName('SVGAnimationElement.getStartTime')
  @DocsEditable()
  double getStartTime() native;

  // From SVGTests

  @DomName('SVGAnimationElement.requiredExtensions')
  @DocsEditable()
  final StringList requiredExtensions;

  @DomName('SVGAnimationElement.requiredFeatures')
  @DocsEditable()
  final StringList requiredFeatures;

  @DomName('SVGAnimationElement.systemLanguage')
  @DocsEditable()
  final StringList systemLanguage;

  @DomName('SVGAnimationElement.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGCircleElement')
@Unstable()
@Native("SVGCircleElement")
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
  final AnimatedLength cx;

  @DomName('SVGCircleElement.cy')
  @DocsEditable()
  final AnimatedLength cy;

  @DomName('SVGCircleElement.r')
  @DocsEditable()
  final AnimatedLength r;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGClipPathElement')
@Unstable()
@Native("SVGClipPathElement")
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
  final AnimatedEnumeration clipPathUnits;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGDefsElement')
@Unstable()
@Native("SVGDefsElement")
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


@DocsEditable()
@DomName('SVGDescElement')
@Unstable()
@Native("SVGDescElement")
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


@DocsEditable()
@DomName('SVGDiscardElement')
@Experimental() // untriaged
@Native("SVGDiscardElement")
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


@DocsEditable()
@DomName('SVGElementInstance')
@Unstable()
@Native("SVGElementInstance")
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
  final SvgElement correspondingElement;

  @DomName('SVGElementInstance.correspondingUseElement')
  @DocsEditable()
  final UseElement correspondingUseElement;

  @DomName('SVGElementInstance.firstChild')
  @DocsEditable()
  final ElementInstance firstChild;

  @DomName('SVGElementInstance.lastChild')
  @DocsEditable()
  final ElementInstance lastChild;

  @DomName('SVGElementInstance.nextSibling')
  @DocsEditable()
  final ElementInstance nextSibling;

  @DomName('SVGElementInstance.parentNode')
  @DocsEditable()
  final ElementInstance parentNode;

  @DomName('SVGElementInstance.previousSibling')
  @DocsEditable()
  final ElementInstance previousSibling;

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


@DocsEditable()
@DomName('SVGEllipseElement')
@Unstable()
@Native("SVGEllipseElement")
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
  final AnimatedLength cx;

  @DomName('SVGEllipseElement.cy')
  @DocsEditable()
  final AnimatedLength cy;

  @DomName('SVGEllipseElement.rx')
  @DocsEditable()
  final AnimatedLength rx;

  @DomName('SVGEllipseElement.ry')
  @DocsEditable()
  final AnimatedLength ry;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFEBlendElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGFEBlendElement")
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
  static bool get supported => SvgElement.isTagSupported('feBlend') && (new SvgElement.tag('feBlend') is FEBlendElement);

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
  final AnimatedString in1;

  @DomName('SVGFEBlendElement.in2')
  @DocsEditable()
  final AnimatedString in2;

  @DomName('SVGFEBlendElement.mode')
  @DocsEditable()
  final AnimatedEnumeration mode;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEBlendElement.height')
  @DocsEditable()
  final AnimatedLength height;

  @DomName('SVGFEBlendElement.result')
  @DocsEditable()
  final AnimatedString result;

  @DomName('SVGFEBlendElement.width')
  @DocsEditable()
  final AnimatedLength width;

  @DomName('SVGFEBlendElement.x')
  @DocsEditable()
  final AnimatedLength x;

  @DomName('SVGFEBlendElement.y')
  @DocsEditable()
  final AnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFEColorMatrixElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGFEColorMatrixElement")
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
  static bool get supported => SvgElement.isTagSupported('feColorMatrix') && (new SvgElement.tag('feColorMatrix') is FEColorMatrixElement);

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
  final AnimatedString in1;

  @DomName('SVGFEColorMatrixElement.type')
  @DocsEditable()
  final AnimatedEnumeration type;

  @DomName('SVGFEColorMatrixElement.values')
  @DocsEditable()
  final AnimatedNumberList values;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEColorMatrixElement.height')
  @DocsEditable()
  final AnimatedLength height;

  @DomName('SVGFEColorMatrixElement.result')
  @DocsEditable()
  final AnimatedString result;

  @DomName('SVGFEColorMatrixElement.width')
  @DocsEditable()
  final AnimatedLength width;

  @DomName('SVGFEColorMatrixElement.x')
  @DocsEditable()
  final AnimatedLength x;

  @DomName('SVGFEColorMatrixElement.y')
  @DocsEditable()
  final AnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFEComponentTransferElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGFEComponentTransferElement")
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
  static bool get supported => SvgElement.isTagSupported('feComponentTransfer') && (new SvgElement.tag('feComponentTransfer') is FEComponentTransferElement);

  @DomName('SVGFEComponentTransferElement.in1')
  @DocsEditable()
  final AnimatedString in1;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEComponentTransferElement.height')
  @DocsEditable()
  final AnimatedLength height;

  @DomName('SVGFEComponentTransferElement.result')
  @DocsEditable()
  final AnimatedString result;

  @DomName('SVGFEComponentTransferElement.width')
  @DocsEditable()
  final AnimatedLength width;

  @DomName('SVGFEComponentTransferElement.x')
  @DocsEditable()
  final AnimatedLength x;

  @DomName('SVGFEComponentTransferElement.y')
  @DocsEditable()
  final AnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFECompositeElement')
@Unstable()
@Native("SVGFECompositeElement")
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
  final AnimatedString in1;

  @DomName('SVGFECompositeElement.in2')
  @DocsEditable()
  final AnimatedString in2;

  @DomName('SVGFECompositeElement.k1')
  @DocsEditable()
  final AnimatedNumber k1;

  @DomName('SVGFECompositeElement.k2')
  @DocsEditable()
  final AnimatedNumber k2;

  @DomName('SVGFECompositeElement.k3')
  @DocsEditable()
  final AnimatedNumber k3;

  @DomName('SVGFECompositeElement.k4')
  @DocsEditable()
  final AnimatedNumber k4;

  @DomName('SVGFECompositeElement.operator')
  @DocsEditable()
  final AnimatedEnumeration operator;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFECompositeElement.height')
  @DocsEditable()
  final AnimatedLength height;

  @DomName('SVGFECompositeElement.result')
  @DocsEditable()
  final AnimatedString result;

  @DomName('SVGFECompositeElement.width')
  @DocsEditable()
  final AnimatedLength width;

  @DomName('SVGFECompositeElement.x')
  @DocsEditable()
  final AnimatedLength x;

  @DomName('SVGFECompositeElement.y')
  @DocsEditable()
  final AnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFEConvolveMatrixElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGFEConvolveMatrixElement")
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
  static bool get supported => SvgElement.isTagSupported('feConvolveMatrix') && (new SvgElement.tag('feConvolveMatrix') is FEConvolveMatrixElement);

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
  final AnimatedNumber bias;

  @DomName('SVGFEConvolveMatrixElement.divisor')
  @DocsEditable()
  final AnimatedNumber divisor;

  @DomName('SVGFEConvolveMatrixElement.edgeMode')
  @DocsEditable()
  final AnimatedEnumeration edgeMode;

  @DomName('SVGFEConvolveMatrixElement.in1')
  @DocsEditable()
  final AnimatedString in1;

  @DomName('SVGFEConvolveMatrixElement.kernelMatrix')
  @DocsEditable()
  final AnimatedNumberList kernelMatrix;

  @DomName('SVGFEConvolveMatrixElement.kernelUnitLengthX')
  @DocsEditable()
  final AnimatedNumber kernelUnitLengthX;

  @DomName('SVGFEConvolveMatrixElement.kernelUnitLengthY')
  @DocsEditable()
  final AnimatedNumber kernelUnitLengthY;

  @DomName('SVGFEConvolveMatrixElement.orderX')
  @DocsEditable()
  final AnimatedInteger orderX;

  @DomName('SVGFEConvolveMatrixElement.orderY')
  @DocsEditable()
  final AnimatedInteger orderY;

  @DomName('SVGFEConvolveMatrixElement.preserveAlpha')
  @DocsEditable()
  final AnimatedBoolean preserveAlpha;

  @DomName('SVGFEConvolveMatrixElement.targetX')
  @DocsEditable()
  final AnimatedInteger targetX;

  @DomName('SVGFEConvolveMatrixElement.targetY')
  @DocsEditable()
  final AnimatedInteger targetY;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEConvolveMatrixElement.height')
  @DocsEditable()
  final AnimatedLength height;

  @DomName('SVGFEConvolveMatrixElement.result')
  @DocsEditable()
  final AnimatedString result;

  @DomName('SVGFEConvolveMatrixElement.width')
  @DocsEditable()
  final AnimatedLength width;

  @DomName('SVGFEConvolveMatrixElement.x')
  @DocsEditable()
  final AnimatedLength x;

  @DomName('SVGFEConvolveMatrixElement.y')
  @DocsEditable()
  final AnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFEDiffuseLightingElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGFEDiffuseLightingElement")
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
  static bool get supported => SvgElement.isTagSupported('feDiffuseLighting') && (new SvgElement.tag('feDiffuseLighting') is FEDiffuseLightingElement);

  @DomName('SVGFEDiffuseLightingElement.diffuseConstant')
  @DocsEditable()
  final AnimatedNumber diffuseConstant;

  @DomName('SVGFEDiffuseLightingElement.in1')
  @DocsEditable()
  final AnimatedString in1;

  @DomName('SVGFEDiffuseLightingElement.kernelUnitLengthX')
  @DocsEditable()
  final AnimatedNumber kernelUnitLengthX;

  @DomName('SVGFEDiffuseLightingElement.kernelUnitLengthY')
  @DocsEditable()
  final AnimatedNumber kernelUnitLengthY;

  @DomName('SVGFEDiffuseLightingElement.surfaceScale')
  @DocsEditable()
  final AnimatedNumber surfaceScale;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEDiffuseLightingElement.height')
  @DocsEditable()
  final AnimatedLength height;

  @DomName('SVGFEDiffuseLightingElement.result')
  @DocsEditable()
  final AnimatedString result;

  @DomName('SVGFEDiffuseLightingElement.width')
  @DocsEditable()
  final AnimatedLength width;

  @DomName('SVGFEDiffuseLightingElement.x')
  @DocsEditable()
  final AnimatedLength x;

  @DomName('SVGFEDiffuseLightingElement.y')
  @DocsEditable()
  final AnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFEDisplacementMapElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGFEDisplacementMapElement")
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
  static bool get supported => SvgElement.isTagSupported('feDisplacementMap') && (new SvgElement.tag('feDisplacementMap') is FEDisplacementMapElement);

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
  final AnimatedString in1;

  @DomName('SVGFEDisplacementMapElement.in2')
  @DocsEditable()
  final AnimatedString in2;

  @DomName('SVGFEDisplacementMapElement.scale')
  @DocsEditable()
  final AnimatedNumber scale;

  @DomName('SVGFEDisplacementMapElement.xChannelSelector')
  @DocsEditable()
  final AnimatedEnumeration xChannelSelector;

  @DomName('SVGFEDisplacementMapElement.yChannelSelector')
  @DocsEditable()
  final AnimatedEnumeration yChannelSelector;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEDisplacementMapElement.height')
  @DocsEditable()
  final AnimatedLength height;

  @DomName('SVGFEDisplacementMapElement.result')
  @DocsEditable()
  final AnimatedString result;

  @DomName('SVGFEDisplacementMapElement.width')
  @DocsEditable()
  final AnimatedLength width;

  @DomName('SVGFEDisplacementMapElement.x')
  @DocsEditable()
  final AnimatedLength x;

  @DomName('SVGFEDisplacementMapElement.y')
  @DocsEditable()
  final AnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFEDistantLightElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGFEDistantLightElement")
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
  static bool get supported => SvgElement.isTagSupported('feDistantLight') && (new SvgElement.tag('feDistantLight') is FEDistantLightElement);

  @DomName('SVGFEDistantLightElement.azimuth')
  @DocsEditable()
  final AnimatedNumber azimuth;

  @DomName('SVGFEDistantLightElement.elevation')
  @DocsEditable()
  final AnimatedNumber elevation;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFEFloodElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGFEFloodElement")
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
  static bool get supported => SvgElement.isTagSupported('feFlood') && (new SvgElement.tag('feFlood') is FEFloodElement);

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEFloodElement.height')
  @DocsEditable()
  final AnimatedLength height;

  @DomName('SVGFEFloodElement.result')
  @DocsEditable()
  final AnimatedString result;

  @DomName('SVGFEFloodElement.width')
  @DocsEditable()
  final AnimatedLength width;

  @DomName('SVGFEFloodElement.x')
  @DocsEditable()
  final AnimatedLength x;

  @DomName('SVGFEFloodElement.y')
  @DocsEditable()
  final AnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFEFuncAElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGFEFuncAElement")
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
  static bool get supported => SvgElement.isTagSupported('feFuncA') && (new SvgElement.tag('feFuncA') is FEFuncAElement);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFEFuncBElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGFEFuncBElement")
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
  static bool get supported => SvgElement.isTagSupported('feFuncB') && (new SvgElement.tag('feFuncB') is FEFuncBElement);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFEFuncGElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGFEFuncGElement")
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
  static bool get supported => SvgElement.isTagSupported('feFuncG') && (new SvgElement.tag('feFuncG') is FEFuncGElement);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFEFuncRElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGFEFuncRElement")
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
  static bool get supported => SvgElement.isTagSupported('feFuncR') && (new SvgElement.tag('feFuncR') is FEFuncRElement);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFEGaussianBlurElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGFEGaussianBlurElement")
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
  static bool get supported => SvgElement.isTagSupported('feGaussianBlur') && (new SvgElement.tag('feGaussianBlur') is FEGaussianBlurElement);

  @DomName('SVGFEGaussianBlurElement.in1')
  @DocsEditable()
  final AnimatedString in1;

  @DomName('SVGFEGaussianBlurElement.stdDeviationX')
  @DocsEditable()
  final AnimatedNumber stdDeviationX;

  @DomName('SVGFEGaussianBlurElement.stdDeviationY')
  @DocsEditable()
  final AnimatedNumber stdDeviationY;

  @DomName('SVGFEGaussianBlurElement.setStdDeviation')
  @DocsEditable()
  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEGaussianBlurElement.height')
  @DocsEditable()
  final AnimatedLength height;

  @DomName('SVGFEGaussianBlurElement.result')
  @DocsEditable()
  final AnimatedString result;

  @DomName('SVGFEGaussianBlurElement.width')
  @DocsEditable()
  final AnimatedLength width;

  @DomName('SVGFEGaussianBlurElement.x')
  @DocsEditable()
  final AnimatedLength x;

  @DomName('SVGFEGaussianBlurElement.y')
  @DocsEditable()
  final AnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFEImageElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGFEImageElement")
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
  static bool get supported => SvgElement.isTagSupported('feImage') && (new SvgElement.tag('feImage') is FEImageElement);

  @DomName('SVGFEImageElement.preserveAspectRatio')
  @DocsEditable()
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEImageElement.height')
  @DocsEditable()
  final AnimatedLength height;

  @DomName('SVGFEImageElement.result')
  @DocsEditable()
  final AnimatedString result;

  @DomName('SVGFEImageElement.width')
  @DocsEditable()
  final AnimatedLength width;

  @DomName('SVGFEImageElement.x')
  @DocsEditable()
  final AnimatedLength x;

  @DomName('SVGFEImageElement.y')
  @DocsEditable()
  final AnimatedLength y;

  // From SVGURIReference

  @DomName('SVGFEImageElement.href')
  @DocsEditable()
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFEMergeElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGFEMergeElement")
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
  static bool get supported => SvgElement.isTagSupported('feMerge') && (new SvgElement.tag('feMerge') is FEMergeElement);

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEMergeElement.height')
  @DocsEditable()
  final AnimatedLength height;

  @DomName('SVGFEMergeElement.result')
  @DocsEditable()
  final AnimatedString result;

  @DomName('SVGFEMergeElement.width')
  @DocsEditable()
  final AnimatedLength width;

  @DomName('SVGFEMergeElement.x')
  @DocsEditable()
  final AnimatedLength x;

  @DomName('SVGFEMergeElement.y')
  @DocsEditable()
  final AnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFEMergeNodeElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGFEMergeNodeElement")
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
  static bool get supported => SvgElement.isTagSupported('feMergeNode') && (new SvgElement.tag('feMergeNode') is FEMergeNodeElement);

  @DomName('SVGFEMergeNodeElement.in1')
  @DocsEditable()
  final AnimatedString in1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFEMorphologyElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGFEMorphologyElement")
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
  final AnimatedString in1;

  @DomName('SVGFEMorphologyElement.operator')
  @DocsEditable()
  final AnimatedEnumeration operator;

  @DomName('SVGFEMorphologyElement.radiusX')
  @DocsEditable()
  final AnimatedNumber radiusX;

  @DomName('SVGFEMorphologyElement.radiusY')
  @DocsEditable()
  final AnimatedNumber radiusY;

  @DomName('SVGFEMorphologyElement.setRadius')
  @DocsEditable()
  void setRadius(num radiusX, num radiusY) native;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEMorphologyElement.height')
  @DocsEditable()
  final AnimatedLength height;

  @DomName('SVGFEMorphologyElement.result')
  @DocsEditable()
  final AnimatedString result;

  @DomName('SVGFEMorphologyElement.width')
  @DocsEditable()
  final AnimatedLength width;

  @DomName('SVGFEMorphologyElement.x')
  @DocsEditable()
  final AnimatedLength x;

  @DomName('SVGFEMorphologyElement.y')
  @DocsEditable()
  final AnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFEOffsetElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGFEOffsetElement")
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
  static bool get supported => SvgElement.isTagSupported('feOffset') && (new SvgElement.tag('feOffset') is FEOffsetElement);

  @DomName('SVGFEOffsetElement.dx')
  @DocsEditable()
  final AnimatedNumber dx;

  @DomName('SVGFEOffsetElement.dy')
  @DocsEditable()
  final AnimatedNumber dy;

  @DomName('SVGFEOffsetElement.in1')
  @DocsEditable()
  final AnimatedString in1;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEOffsetElement.height')
  @DocsEditable()
  final AnimatedLength height;

  @DomName('SVGFEOffsetElement.result')
  @DocsEditable()
  final AnimatedString result;

  @DomName('SVGFEOffsetElement.width')
  @DocsEditable()
  final AnimatedLength width;

  @DomName('SVGFEOffsetElement.x')
  @DocsEditable()
  final AnimatedLength x;

  @DomName('SVGFEOffsetElement.y')
  @DocsEditable()
  final AnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFEPointLightElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGFEPointLightElement")
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
  static bool get supported => SvgElement.isTagSupported('fePointLight') && (new SvgElement.tag('fePointLight') is FEPointLightElement);

  @DomName('SVGFEPointLightElement.x')
  @DocsEditable()
  final AnimatedNumber x;

  @DomName('SVGFEPointLightElement.y')
  @DocsEditable()
  final AnimatedNumber y;

  @DomName('SVGFEPointLightElement.z')
  @DocsEditable()
  final AnimatedNumber z;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFESpecularLightingElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGFESpecularLightingElement")
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
  static bool get supported => SvgElement.isTagSupported('feSpecularLighting') && (new SvgElement.tag('feSpecularLighting') is FESpecularLightingElement);

  @DomName('SVGFESpecularLightingElement.in1')
  @DocsEditable()
  final AnimatedString in1;

  @DomName('SVGFESpecularLightingElement.specularConstant')
  @DocsEditable()
  final AnimatedNumber specularConstant;

  @DomName('SVGFESpecularLightingElement.specularExponent')
  @DocsEditable()
  final AnimatedNumber specularExponent;

  @DomName('SVGFESpecularLightingElement.surfaceScale')
  @DocsEditable()
  final AnimatedNumber surfaceScale;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFESpecularLightingElement.height')
  @DocsEditable()
  final AnimatedLength height;

  @DomName('SVGFESpecularLightingElement.result')
  @DocsEditable()
  final AnimatedString result;

  @DomName('SVGFESpecularLightingElement.width')
  @DocsEditable()
  final AnimatedLength width;

  @DomName('SVGFESpecularLightingElement.x')
  @DocsEditable()
  final AnimatedLength x;

  @DomName('SVGFESpecularLightingElement.y')
  @DocsEditable()
  final AnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFESpotLightElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGFESpotLightElement")
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
  static bool get supported => SvgElement.isTagSupported('feSpotLight') && (new SvgElement.tag('feSpotLight') is FESpotLightElement);

  @DomName('SVGFESpotLightElement.limitingConeAngle')
  @DocsEditable()
  final AnimatedNumber limitingConeAngle;

  @DomName('SVGFESpotLightElement.pointsAtX')
  @DocsEditable()
  final AnimatedNumber pointsAtX;

  @DomName('SVGFESpotLightElement.pointsAtY')
  @DocsEditable()
  final AnimatedNumber pointsAtY;

  @DomName('SVGFESpotLightElement.pointsAtZ')
  @DocsEditable()
  final AnimatedNumber pointsAtZ;

  @DomName('SVGFESpotLightElement.specularExponent')
  @DocsEditable()
  final AnimatedNumber specularExponent;

  @DomName('SVGFESpotLightElement.x')
  @DocsEditable()
  final AnimatedNumber x;

  @DomName('SVGFESpotLightElement.y')
  @DocsEditable()
  final AnimatedNumber y;

  @DomName('SVGFESpotLightElement.z')
  @DocsEditable()
  final AnimatedNumber z;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFETileElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGFETileElement")
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
  static bool get supported => SvgElement.isTagSupported('feTile') && (new SvgElement.tag('feTile') is FETileElement);

  @DomName('SVGFETileElement.in1')
  @DocsEditable()
  final AnimatedString in1;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFETileElement.height')
  @DocsEditable()
  final AnimatedLength height;

  @DomName('SVGFETileElement.result')
  @DocsEditable()
  final AnimatedString result;

  @DomName('SVGFETileElement.width')
  @DocsEditable()
  final AnimatedLength width;

  @DomName('SVGFETileElement.x')
  @DocsEditable()
  final AnimatedLength x;

  @DomName('SVGFETileElement.y')
  @DocsEditable()
  final AnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFETurbulenceElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGFETurbulenceElement")
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
  static bool get supported => SvgElement.isTagSupported('feTurbulence') && (new SvgElement.tag('feTurbulence') is FETurbulenceElement);

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
  final AnimatedNumber baseFrequencyX;

  @DomName('SVGFETurbulenceElement.baseFrequencyY')
  @DocsEditable()
  final AnimatedNumber baseFrequencyY;

  @DomName('SVGFETurbulenceElement.numOctaves')
  @DocsEditable()
  final AnimatedInteger numOctaves;

  @DomName('SVGFETurbulenceElement.seed')
  @DocsEditable()
  final AnimatedNumber seed;

  @DomName('SVGFETurbulenceElement.stitchTiles')
  @DocsEditable()
  final AnimatedEnumeration stitchTiles;

  @DomName('SVGFETurbulenceElement.type')
  @DocsEditable()
  final AnimatedEnumeration type;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFETurbulenceElement.height')
  @DocsEditable()
  final AnimatedLength height;

  @DomName('SVGFETurbulenceElement.result')
  @DocsEditable()
  final AnimatedString result;

  @DomName('SVGFETurbulenceElement.width')
  @DocsEditable()
  final AnimatedLength width;

  @DomName('SVGFETurbulenceElement.x')
  @DocsEditable()
  final AnimatedLength x;

  @DomName('SVGFETurbulenceElement.y')
  @DocsEditable()
  final AnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFilterElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGFilterElement")
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
  static bool get supported => SvgElement.isTagSupported('filter') && (new SvgElement.tag('filter') is FilterElement);

  @DomName('SVGFilterElement.filterResX')
  @DocsEditable()
  final AnimatedInteger filterResX;

  @DomName('SVGFilterElement.filterResY')
  @DocsEditable()
  final AnimatedInteger filterResY;

  @DomName('SVGFilterElement.filterUnits')
  @DocsEditable()
  final AnimatedEnumeration filterUnits;

  @DomName('SVGFilterElement.height')
  @DocsEditable()
  final AnimatedLength height;

  @DomName('SVGFilterElement.primitiveUnits')
  @DocsEditable()
  final AnimatedEnumeration primitiveUnits;

  @DomName('SVGFilterElement.width')
  @DocsEditable()
  final AnimatedLength width;

  @DomName('SVGFilterElement.x')
  @DocsEditable()
  final AnimatedLength x;

  @DomName('SVGFilterElement.y')
  @DocsEditable()
  final AnimatedLength y;

  @DomName('SVGFilterElement.setFilterRes')
  @DocsEditable()
  void setFilterRes(int filterResX, int filterResY) native;

  // From SVGURIReference

  @DomName('SVGFilterElement.href')
  @DocsEditable()
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFilterPrimitiveStandardAttributes')
@Unstable()
abstract class FilterPrimitiveStandardAttributes extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory FilterPrimitiveStandardAttributes._() { throw new UnsupportedError("Not supported"); }

  final AnimatedLength height;

  final AnimatedString result;

  final AnimatedLength width;

  final AnimatedLength x;

  final AnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFitToViewBox')
@Unstable()
abstract class FitToViewBox extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory FitToViewBox._() { throw new UnsupportedError("Not supported"); }

  final AnimatedPreserveAspectRatio preserveAspectRatio;

  final AnimatedRect viewBox;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGForeignObjectElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGForeignObjectElement")
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
  static bool get supported => SvgElement.isTagSupported('foreignObject') && (new SvgElement.tag('foreignObject') is ForeignObjectElement);

  @DomName('SVGForeignObjectElement.height')
  @DocsEditable()
  final AnimatedLength height;

  @DomName('SVGForeignObjectElement.width')
  @DocsEditable()
  final AnimatedLength width;

  @DomName('SVGForeignObjectElement.x')
  @DocsEditable()
  final AnimatedLength x;

  @DomName('SVGForeignObjectElement.y')
  @DocsEditable()
  final AnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGGElement')
@Unstable()
@Native("SVGGElement")
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


@DocsEditable()
@DomName('SVGGeometryElement')
@Experimental() // untriaged
@Native("SVGGeometryElement")
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
  bool isPointInFill(Point point) native;

  @DomName('SVGGeometryElement.isPointInStroke')
  @DocsEditable()
  @Experimental() // untriaged
  bool isPointInStroke(Point point) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGGraphicsElement')
@Experimental() // untriaged
@Native("SVGGraphicsElement")
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
  final SvgElement farthestViewportElement;

  @DomName('SVGGraphicsElement.nearestViewportElement')
  @DocsEditable()
  @Experimental() // untriaged
  final SvgElement nearestViewportElement;

  @DomName('SVGGraphicsElement.transform')
  @DocsEditable()
  @Experimental() // untriaged
  final AnimatedTransformList transform;

  @DomName('SVGGraphicsElement.getBBox')
  @DocsEditable()
  @Experimental() // untriaged
  Rect getBBox() native;

  @JSName('getCTM')
  @DomName('SVGGraphicsElement.getCTM')
  @DocsEditable()
  @Experimental() // untriaged
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DomName('SVGGraphicsElement.getScreenCTM')
  @DocsEditable()
  @Experimental() // untriaged
  Matrix getScreenCtm() native;

  @DomName('SVGGraphicsElement.getTransformToElement')
  @DocsEditable()
  @Experimental() // untriaged
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGTests

  @DomName('SVGGraphicsElement.requiredExtensions')
  @DocsEditable()
  @Experimental() // untriaged
  final StringList requiredExtensions;

  @DomName('SVGGraphicsElement.requiredFeatures')
  @DocsEditable()
  @Experimental() // untriaged
  final StringList requiredFeatures;

  @DomName('SVGGraphicsElement.systemLanguage')
  @DocsEditable()
  @Experimental() // untriaged
  final StringList systemLanguage;

  @DomName('SVGGraphicsElement.hasExtension')
  @DocsEditable()
  @Experimental() // untriaged
  bool hasExtension(String extension) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGImageElement')
@Unstable()
@Native("SVGImageElement")
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
  final AnimatedLength height;

  @DomName('SVGImageElement.preserveAspectRatio')
  @DocsEditable()
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  @DomName('SVGImageElement.width')
  @DocsEditable()
  final AnimatedLength width;

  @DomName('SVGImageElement.x')
  @DocsEditable()
  final AnimatedLength x;

  @DomName('SVGImageElement.y')
  @DocsEditable()
  final AnimatedLength y;

  // From SVGURIReference

  @DomName('SVGImageElement.href')
  @DocsEditable()
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGLength')
@Unstable()
@Native("SVGLength")
class Length extends Interceptor {
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
  final int unitType;

  @DomName('SVGLength.value')
  @DocsEditable()
  num value;

  @DomName('SVGLength.valueAsString')
  @DocsEditable()
  String valueAsString;

  @DomName('SVGLength.valueInSpecifiedUnits')
  @DocsEditable()
  num valueInSpecifiedUnits;

  @DomName('SVGLength.convertToSpecifiedUnits')
  @DocsEditable()
  void convertToSpecifiedUnits(int unitType) native;

  @DomName('SVGLength.newValueSpecifiedUnits')
  @DocsEditable()
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGLengthList')
@Unstable()
@Native("SVGLengthList")
class LengthList extends Interceptor with ListMixin<Length>, ImmutableListMixin<Length> implements List<Length> {
  // To suppress missing implicit constructor warnings.
  factory LengthList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGLengthList.numberOfItems')
  @DocsEditable()
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
  @DocsEditable()
  Length appendItem(Length item) native;

  @DomName('SVGLengthList.clear')
  @DocsEditable()
  void clear() native;

  @DomName('SVGLengthList.getItem')
  @DocsEditable()
  Length getItem(int index) native;

  @DomName('SVGLengthList.initialize')
  @DocsEditable()
  Length initialize(Length item) native;

  @DomName('SVGLengthList.insertItemBefore')
  @DocsEditable()
  Length insertItemBefore(Length item, int index) native;

  @DomName('SVGLengthList.removeItem')
  @DocsEditable()
  Length removeItem(int index) native;

  @DomName('SVGLengthList.replaceItem')
  @DocsEditable()
  Length replaceItem(Length item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGLineElement')
@Unstable()
@Native("SVGLineElement")
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
  final AnimatedLength x1;

  @DomName('SVGLineElement.x2')
  @DocsEditable()
  final AnimatedLength x2;

  @DomName('SVGLineElement.y1')
  @DocsEditable()
  final AnimatedLength y1;

  @DomName('SVGLineElement.y2')
  @DocsEditable()
  final AnimatedLength y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGLinearGradientElement')
@Unstable()
@Native("SVGLinearGradientElement")
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
  final AnimatedLength x1;

  @DomName('SVGLinearGradientElement.x2')
  @DocsEditable()
  final AnimatedLength x2;

  @DomName('SVGLinearGradientElement.y1')
  @DocsEditable()
  final AnimatedLength y1;

  @DomName('SVGLinearGradientElement.y2')
  @DocsEditable()
  final AnimatedLength y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGMarkerElement')
@Unstable()
@Native("SVGMarkerElement")
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
  final AnimatedLength markerHeight;

  @DomName('SVGMarkerElement.markerUnits')
  @DocsEditable()
  final AnimatedEnumeration markerUnits;

  @DomName('SVGMarkerElement.markerWidth')
  @DocsEditable()
  final AnimatedLength markerWidth;

  @DomName('SVGMarkerElement.orientAngle')
  @DocsEditable()
  final AnimatedAngle orientAngle;

  @DomName('SVGMarkerElement.orientType')
  @DocsEditable()
  final AnimatedEnumeration orientType;

  @DomName('SVGMarkerElement.refX')
  @DocsEditable()
  final AnimatedLength refX;

  @DomName('SVGMarkerElement.refY')
  @DocsEditable()
  final AnimatedLength refY;

  @DomName('SVGMarkerElement.setOrientToAngle')
  @DocsEditable()
  void setOrientToAngle(Angle angle) native;

  @DomName('SVGMarkerElement.setOrientToAuto')
  @DocsEditable()
  void setOrientToAuto() native;

  // From SVGFitToViewBox

  @DomName('SVGMarkerElement.preserveAspectRatio')
  @DocsEditable()
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  @DomName('SVGMarkerElement.viewBox')
  @DocsEditable()
  final AnimatedRect viewBox;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGMaskElement')
@Unstable()
@Native("SVGMaskElement")
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
  final AnimatedLength height;

  @DomName('SVGMaskElement.maskContentUnits')
  @DocsEditable()
  final AnimatedEnumeration maskContentUnits;

  @DomName('SVGMaskElement.maskUnits')
  @DocsEditable()
  final AnimatedEnumeration maskUnits;

  @DomName('SVGMaskElement.width')
  @DocsEditable()
  final AnimatedLength width;

  @DomName('SVGMaskElement.x')
  @DocsEditable()
  final AnimatedLength x;

  @DomName('SVGMaskElement.y')
  @DocsEditable()
  final AnimatedLength y;

  // From SVGTests

  @DomName('SVGMaskElement.requiredExtensions')
  @DocsEditable()
  final StringList requiredExtensions;

  @DomName('SVGMaskElement.requiredFeatures')
  @DocsEditable()
  final StringList requiredFeatures;

  @DomName('SVGMaskElement.systemLanguage')
  @DocsEditable()
  final StringList systemLanguage;

  @DomName('SVGMaskElement.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGMatrix')
@Unstable()
@Native("SVGMatrix")
class Matrix extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory Matrix._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGMatrix.a')
  @DocsEditable()
  num a;

  @DomName('SVGMatrix.b')
  @DocsEditable()
  num b;

  @DomName('SVGMatrix.c')
  @DocsEditable()
  num c;

  @DomName('SVGMatrix.d')
  @DocsEditable()
  num d;

  @DomName('SVGMatrix.e')
  @DocsEditable()
  num e;

  @DomName('SVGMatrix.f')
  @DocsEditable()
  num f;

  @DomName('SVGMatrix.flipX')
  @DocsEditable()
  Matrix flipX() native;

  @DomName('SVGMatrix.flipY')
  @DocsEditable()
  Matrix flipY() native;

  @DomName('SVGMatrix.inverse')
  @DocsEditable()
  Matrix inverse() native;

  @DomName('SVGMatrix.multiply')
  @DocsEditable()
  Matrix multiply(Matrix secondMatrix) native;

  @DomName('SVGMatrix.rotate')
  @DocsEditable()
  Matrix rotate(num angle) native;

  @DomName('SVGMatrix.rotateFromVector')
  @DocsEditable()
  Matrix rotateFromVector(num x, num y) native;

  @DomName('SVGMatrix.scale')
  @DocsEditable()
  Matrix scale(num scaleFactor) native;

  @DomName('SVGMatrix.scaleNonUniform')
  @DocsEditable()
  Matrix scaleNonUniform(num scaleFactorX, num scaleFactorY) native;

  @DomName('SVGMatrix.skewX')
  @DocsEditable()
  Matrix skewX(num angle) native;

  @DomName('SVGMatrix.skewY')
  @DocsEditable()
  Matrix skewY(num angle) native;

  @DomName('SVGMatrix.translate')
  @DocsEditable()
  Matrix translate(num x, num y) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGMetadataElement')
@Unstable()
@Native("SVGMetadataElement")
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


@DocsEditable()
@DomName('SVGNumber')
@Unstable()
@Native("SVGNumber")
class Number extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory Number._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGNumber.value')
  @DocsEditable()
  num value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGNumberList')
@Unstable()
@Native("SVGNumberList")
class NumberList extends Interceptor with ListMixin<Number>, ImmutableListMixin<Number> implements List<Number> {
  // To suppress missing implicit constructor warnings.
  factory NumberList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGNumberList.numberOfItems')
  @DocsEditable()
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
  @DocsEditable()
  Number appendItem(Number item) native;

  @DomName('SVGNumberList.clear')
  @DocsEditable()
  void clear() native;

  @DomName('SVGNumberList.getItem')
  @DocsEditable()
  Number getItem(int index) native;

  @DomName('SVGNumberList.initialize')
  @DocsEditable()
  Number initialize(Number item) native;

  @DomName('SVGNumberList.insertItemBefore')
  @DocsEditable()
  Number insertItemBefore(Number item, int index) native;

  @DomName('SVGNumberList.removeItem')
  @DocsEditable()
  Number removeItem(int index) native;

  @DomName('SVGNumberList.replaceItem')
  @DocsEditable()
  Number replaceItem(Number item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPathElement')
@Unstable()
@Native("SVGPathElement")
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
  final PathSegList animatedNormalizedPathSegList;

  @DomName('SVGPathElement.animatedPathSegList')
  @DocsEditable()
  final PathSegList animatedPathSegList;

  @DomName('SVGPathElement.normalizedPathSegList')
  @DocsEditable()
  final PathSegList normalizedPathSegList;

  @DomName('SVGPathElement.pathLength')
  @DocsEditable()
  final AnimatedNumber pathLength;

  @DomName('SVGPathElement.pathSegList')
  @DocsEditable()
  final PathSegList pathSegList;

  @JSName('createSVGPathSegArcAbs')
  @DomName('SVGPathElement.createSVGPathSegArcAbs')
  @DocsEditable()
  PathSegArcAbs createSvgPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  @JSName('createSVGPathSegArcRel')
  @DomName('SVGPathElement.createSVGPathSegArcRel')
  @DocsEditable()
  PathSegArcRel createSvgPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  @JSName('createSVGPathSegClosePath')
  @DomName('SVGPathElement.createSVGPathSegClosePath')
  @DocsEditable()
  PathSegClosePath createSvgPathSegClosePath() native;

  @JSName('createSVGPathSegCurvetoCubicAbs')
  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicAbs')
  @DocsEditable()
  PathSegCurvetoCubicAbs createSvgPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) native;

  @JSName('createSVGPathSegCurvetoCubicRel')
  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicRel')
  @DocsEditable()
  PathSegCurvetoCubicRel createSvgPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) native;

  @JSName('createSVGPathSegCurvetoCubicSmoothAbs')
  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicSmoothAbs')
  @DocsEditable()
  PathSegCurvetoCubicSmoothAbs createSvgPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) native;

  @JSName('createSVGPathSegCurvetoCubicSmoothRel')
  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicSmoothRel')
  @DocsEditable()
  PathSegCurvetoCubicSmoothRel createSvgPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) native;

  @JSName('createSVGPathSegCurvetoQuadraticAbs')
  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticAbs')
  @DocsEditable()
  PathSegCurvetoQuadraticAbs createSvgPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) native;

  @JSName('createSVGPathSegCurvetoQuadraticRel')
  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticRel')
  @DocsEditable()
  PathSegCurvetoQuadraticRel createSvgPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) native;

  @JSName('createSVGPathSegCurvetoQuadraticSmoothAbs')
  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothAbs')
  @DocsEditable()
  PathSegCurvetoQuadraticSmoothAbs createSvgPathSegCurvetoQuadraticSmoothAbs(num x, num y) native;

  @JSName('createSVGPathSegCurvetoQuadraticSmoothRel')
  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothRel')
  @DocsEditable()
  PathSegCurvetoQuadraticSmoothRel createSvgPathSegCurvetoQuadraticSmoothRel(num x, num y) native;

  @JSName('createSVGPathSegLinetoAbs')
  @DomName('SVGPathElement.createSVGPathSegLinetoAbs')
  @DocsEditable()
  PathSegLinetoAbs createSvgPathSegLinetoAbs(num x, num y) native;

  @JSName('createSVGPathSegLinetoHorizontalAbs')
  @DomName('SVGPathElement.createSVGPathSegLinetoHorizontalAbs')
  @DocsEditable()
  PathSegLinetoHorizontalAbs createSvgPathSegLinetoHorizontalAbs(num x) native;

  @JSName('createSVGPathSegLinetoHorizontalRel')
  @DomName('SVGPathElement.createSVGPathSegLinetoHorizontalRel')
  @DocsEditable()
  PathSegLinetoHorizontalRel createSvgPathSegLinetoHorizontalRel(num x) native;

  @JSName('createSVGPathSegLinetoRel')
  @DomName('SVGPathElement.createSVGPathSegLinetoRel')
  @DocsEditable()
  PathSegLinetoRel createSvgPathSegLinetoRel(num x, num y) native;

  @JSName('createSVGPathSegLinetoVerticalAbs')
  @DomName('SVGPathElement.createSVGPathSegLinetoVerticalAbs')
  @DocsEditable()
  PathSegLinetoVerticalAbs createSvgPathSegLinetoVerticalAbs(num y) native;

  @JSName('createSVGPathSegLinetoVerticalRel')
  @DomName('SVGPathElement.createSVGPathSegLinetoVerticalRel')
  @DocsEditable()
  PathSegLinetoVerticalRel createSvgPathSegLinetoVerticalRel(num y) native;

  @JSName('createSVGPathSegMovetoAbs')
  @DomName('SVGPathElement.createSVGPathSegMovetoAbs')
  @DocsEditable()
  PathSegMovetoAbs createSvgPathSegMovetoAbs(num x, num y) native;

  @JSName('createSVGPathSegMovetoRel')
  @DomName('SVGPathElement.createSVGPathSegMovetoRel')
  @DocsEditable()
  PathSegMovetoRel createSvgPathSegMovetoRel(num x, num y) native;

  @DomName('SVGPathElement.getPathSegAtLength')
  @DocsEditable()
  int getPathSegAtLength(num distance) native;

  @DomName('SVGPathElement.getPointAtLength')
  @DocsEditable()
  Point getPointAtLength(num distance) native;

  @DomName('SVGPathElement.getTotalLength')
  @DocsEditable()
  double getTotalLength() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPathSeg')
@Unstable()
@Native("SVGPathSeg")
class PathSeg extends Interceptor {
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
  final int pathSegType;

  @DomName('SVGPathSeg.pathSegTypeAsLetter')
  @DocsEditable()
  final String pathSegTypeAsLetter;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPathSegArcAbs')
@Unstable()
@Native("SVGPathSegArcAbs")
class PathSegArcAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegArcAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegArcAbs.angle')
  @DocsEditable()
  num angle;

  @DomName('SVGPathSegArcAbs.largeArcFlag')
  @DocsEditable()
  bool largeArcFlag;

  @DomName('SVGPathSegArcAbs.r1')
  @DocsEditable()
  num r1;

  @DomName('SVGPathSegArcAbs.r2')
  @DocsEditable()
  num r2;

  @DomName('SVGPathSegArcAbs.sweepFlag')
  @DocsEditable()
  bool sweepFlag;

  @DomName('SVGPathSegArcAbs.x')
  @DocsEditable()
  num x;

  @DomName('SVGPathSegArcAbs.y')
  @DocsEditable()
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPathSegArcRel')
@Unstable()
@Native("SVGPathSegArcRel")
class PathSegArcRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegArcRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegArcRel.angle')
  @DocsEditable()
  num angle;

  @DomName('SVGPathSegArcRel.largeArcFlag')
  @DocsEditable()
  bool largeArcFlag;

  @DomName('SVGPathSegArcRel.r1')
  @DocsEditable()
  num r1;

  @DomName('SVGPathSegArcRel.r2')
  @DocsEditable()
  num r2;

  @DomName('SVGPathSegArcRel.sweepFlag')
  @DocsEditable()
  bool sweepFlag;

  @DomName('SVGPathSegArcRel.x')
  @DocsEditable()
  num x;

  @DomName('SVGPathSegArcRel.y')
  @DocsEditable()
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPathSegClosePath')
@Unstable()
@Native("SVGPathSegClosePath")
class PathSegClosePath extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegClosePath._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPathSegCurvetoCubicAbs')
@Unstable()
@Native("SVGPathSegCurvetoCubicAbs")
class PathSegCurvetoCubicAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoCubicAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegCurvetoCubicAbs.x')
  @DocsEditable()
  num x;

  @DomName('SVGPathSegCurvetoCubicAbs.x1')
  @DocsEditable()
  num x1;

  @DomName('SVGPathSegCurvetoCubicAbs.x2')
  @DocsEditable()
  num x2;

  @DomName('SVGPathSegCurvetoCubicAbs.y')
  @DocsEditable()
  num y;

  @DomName('SVGPathSegCurvetoCubicAbs.y1')
  @DocsEditable()
  num y1;

  @DomName('SVGPathSegCurvetoCubicAbs.y2')
  @DocsEditable()
  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPathSegCurvetoCubicRel')
@Unstable()
@Native("SVGPathSegCurvetoCubicRel")
class PathSegCurvetoCubicRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoCubicRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegCurvetoCubicRel.x')
  @DocsEditable()
  num x;

  @DomName('SVGPathSegCurvetoCubicRel.x1')
  @DocsEditable()
  num x1;

  @DomName('SVGPathSegCurvetoCubicRel.x2')
  @DocsEditable()
  num x2;

  @DomName('SVGPathSegCurvetoCubicRel.y')
  @DocsEditable()
  num y;

  @DomName('SVGPathSegCurvetoCubicRel.y1')
  @DocsEditable()
  num y1;

  @DomName('SVGPathSegCurvetoCubicRel.y2')
  @DocsEditable()
  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPathSegCurvetoCubicSmoothAbs')
@Unstable()
@Native("SVGPathSegCurvetoCubicSmoothAbs")
class PathSegCurvetoCubicSmoothAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoCubicSmoothAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x')
  @DocsEditable()
  num x;

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x2')
  @DocsEditable()
  num x2;

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y')
  @DocsEditable()
  num y;

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y2')
  @DocsEditable()
  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPathSegCurvetoCubicSmoothRel')
@Unstable()
@Native("SVGPathSegCurvetoCubicSmoothRel")
class PathSegCurvetoCubicSmoothRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoCubicSmoothRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegCurvetoCubicSmoothRel.x')
  @DocsEditable()
  num x;

  @DomName('SVGPathSegCurvetoCubicSmoothRel.x2')
  @DocsEditable()
  num x2;

  @DomName('SVGPathSegCurvetoCubicSmoothRel.y')
  @DocsEditable()
  num y;

  @DomName('SVGPathSegCurvetoCubicSmoothRel.y2')
  @DocsEditable()
  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPathSegCurvetoQuadraticAbs')
@Unstable()
@Native("SVGPathSegCurvetoQuadraticAbs")
class PathSegCurvetoQuadraticAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoQuadraticAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegCurvetoQuadraticAbs.x')
  @DocsEditable()
  num x;

  @DomName('SVGPathSegCurvetoQuadraticAbs.x1')
  @DocsEditable()
  num x1;

  @DomName('SVGPathSegCurvetoQuadraticAbs.y')
  @DocsEditable()
  num y;

  @DomName('SVGPathSegCurvetoQuadraticAbs.y1')
  @DocsEditable()
  num y1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPathSegCurvetoQuadraticRel')
@Unstable()
@Native("SVGPathSegCurvetoQuadraticRel")
class PathSegCurvetoQuadraticRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoQuadraticRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegCurvetoQuadraticRel.x')
  @DocsEditable()
  num x;

  @DomName('SVGPathSegCurvetoQuadraticRel.x1')
  @DocsEditable()
  num x1;

  @DomName('SVGPathSegCurvetoQuadraticRel.y')
  @DocsEditable()
  num y;

  @DomName('SVGPathSegCurvetoQuadraticRel.y1')
  @DocsEditable()
  num y1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPathSegCurvetoQuadraticSmoothAbs')
@Unstable()
@Native("SVGPathSegCurvetoQuadraticSmoothAbs")
class PathSegCurvetoQuadraticSmoothAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoQuadraticSmoothAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.x')
  @DocsEditable()
  num x;

  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.y')
  @DocsEditable()
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPathSegCurvetoQuadraticSmoothRel')
@Unstable()
@Native("SVGPathSegCurvetoQuadraticSmoothRel")
class PathSegCurvetoQuadraticSmoothRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoQuadraticSmoothRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.x')
  @DocsEditable()
  num x;

  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.y')
  @DocsEditable()
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPathSegLinetoAbs')
@Unstable()
@Native("SVGPathSegLinetoAbs")
class PathSegLinetoAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegLinetoAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegLinetoAbs.x')
  @DocsEditable()
  num x;

  @DomName('SVGPathSegLinetoAbs.y')
  @DocsEditable()
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPathSegLinetoHorizontalAbs')
@Unstable()
@Native("SVGPathSegLinetoHorizontalAbs")
class PathSegLinetoHorizontalAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegLinetoHorizontalAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegLinetoHorizontalAbs.x')
  @DocsEditable()
  num x;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPathSegLinetoHorizontalRel')
@Unstable()
@Native("SVGPathSegLinetoHorizontalRel")
class PathSegLinetoHorizontalRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegLinetoHorizontalRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegLinetoHorizontalRel.x')
  @DocsEditable()
  num x;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPathSegLinetoRel')
@Unstable()
@Native("SVGPathSegLinetoRel")
class PathSegLinetoRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegLinetoRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegLinetoRel.x')
  @DocsEditable()
  num x;

  @DomName('SVGPathSegLinetoRel.y')
  @DocsEditable()
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPathSegLinetoVerticalAbs')
@Unstable()
@Native("SVGPathSegLinetoVerticalAbs")
class PathSegLinetoVerticalAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegLinetoVerticalAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegLinetoVerticalAbs.y')
  @DocsEditable()
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPathSegLinetoVerticalRel')
@Unstable()
@Native("SVGPathSegLinetoVerticalRel")
class PathSegLinetoVerticalRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegLinetoVerticalRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegLinetoVerticalRel.y')
  @DocsEditable()
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPathSegList')
@Unstable()
@Native("SVGPathSegList")
class PathSegList extends Interceptor with ListMixin<PathSeg>, ImmutableListMixin<PathSeg> implements List<PathSeg> {
  // To suppress missing implicit constructor warnings.
  factory PathSegList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegList.numberOfItems')
  @DocsEditable()
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
  @DocsEditable()
  PathSeg appendItem(PathSeg newItem) native;

  @DomName('SVGPathSegList.clear')
  @DocsEditable()
  void clear() native;

  @DomName('SVGPathSegList.getItem')
  @DocsEditable()
  PathSeg getItem(int index) native;

  @DomName('SVGPathSegList.initialize')
  @DocsEditable()
  PathSeg initialize(PathSeg newItem) native;

  @DomName('SVGPathSegList.insertItemBefore')
  @DocsEditable()
  PathSeg insertItemBefore(PathSeg newItem, int index) native;

  @DomName('SVGPathSegList.removeItem')
  @DocsEditable()
  PathSeg removeItem(int index) native;

  @DomName('SVGPathSegList.replaceItem')
  @DocsEditable()
  PathSeg replaceItem(PathSeg newItem, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPathSegMovetoAbs')
@Unstable()
@Native("SVGPathSegMovetoAbs")
class PathSegMovetoAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegMovetoAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegMovetoAbs.x')
  @DocsEditable()
  num x;

  @DomName('SVGPathSegMovetoAbs.y')
  @DocsEditable()
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPathSegMovetoRel')
@Unstable()
@Native("SVGPathSegMovetoRel")
class PathSegMovetoRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegMovetoRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegMovetoRel.x')
  @DocsEditable()
  num x;

  @DomName('SVGPathSegMovetoRel.y')
  @DocsEditable()
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPatternElement')
@Unstable()
@Native("SVGPatternElement")
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
  final AnimatedLength height;

  @DomName('SVGPatternElement.patternContentUnits')
  @DocsEditable()
  final AnimatedEnumeration patternContentUnits;

  @DomName('SVGPatternElement.patternTransform')
  @DocsEditable()
  final AnimatedTransformList patternTransform;

  @DomName('SVGPatternElement.patternUnits')
  @DocsEditable()
  final AnimatedEnumeration patternUnits;

  @DomName('SVGPatternElement.width')
  @DocsEditable()
  final AnimatedLength width;

  @DomName('SVGPatternElement.x')
  @DocsEditable()
  final AnimatedLength x;

  @DomName('SVGPatternElement.y')
  @DocsEditable()
  final AnimatedLength y;

  // From SVGFitToViewBox

  @DomName('SVGPatternElement.preserveAspectRatio')
  @DocsEditable()
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  @DomName('SVGPatternElement.viewBox')
  @DocsEditable()
  final AnimatedRect viewBox;

  // From SVGTests

  @DomName('SVGPatternElement.requiredExtensions')
  @DocsEditable()
  final StringList requiredExtensions;

  @DomName('SVGPatternElement.requiredFeatures')
  @DocsEditable()
  final StringList requiredFeatures;

  @DomName('SVGPatternElement.systemLanguage')
  @DocsEditable()
  final StringList systemLanguage;

  @DomName('SVGPatternElement.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) native;

  // From SVGURIReference

  @DomName('SVGPatternElement.href')
  @DocsEditable()
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPoint')
@Unstable()
@Native("SVGPoint")
class Point extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory Point._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPoint.x')
  @DocsEditable()
  num x;

  @DomName('SVGPoint.y')
  @DocsEditable()
  num y;

  @DomName('SVGPoint.matrixTransform')
  @DocsEditable()
  Point matrixTransform(Matrix matrix) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPointList')
@Unstable()
@Native("SVGPointList")
class PointList extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory PointList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPointList.numberOfItems')
  @DocsEditable()
  final int numberOfItems;

  @DomName('SVGPointList.appendItem')
  @DocsEditable()
  Point appendItem(Point item) native;

  @DomName('SVGPointList.clear')
  @DocsEditable()
  void clear() native;

  @DomName('SVGPointList.getItem')
  @DocsEditable()
  Point getItem(int index) native;

  @DomName('SVGPointList.initialize')
  @DocsEditable()
  Point initialize(Point item) native;

  @DomName('SVGPointList.insertItemBefore')
  @DocsEditable()
  Point insertItemBefore(Point item, int index) native;

  @DomName('SVGPointList.removeItem')
  @DocsEditable()
  Point removeItem(int index) native;

  @DomName('SVGPointList.replaceItem')
  @DocsEditable()
  Point replaceItem(Point item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPolygonElement')
@Unstable()
@Native("SVGPolygonElement")
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
  final PointList animatedPoints;

  @DomName('SVGPolygonElement.points')
  @DocsEditable()
  final PointList points;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPolylineElement')
@Unstable()
@Native("SVGPolylineElement")
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
  final PointList animatedPoints;

  @DomName('SVGPolylineElement.points')
  @DocsEditable()
  final PointList points;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGPreserveAspectRatio')
@Unstable()
@Native("SVGPreserveAspectRatio")
class PreserveAspectRatio extends Interceptor {
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
  int align;

  @DomName('SVGPreserveAspectRatio.meetOrSlice')
  @DocsEditable()
  int meetOrSlice;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGRadialGradientElement')
@Unstable()
@Native("SVGRadialGradientElement")
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
  final AnimatedLength cx;

  @DomName('SVGRadialGradientElement.cy')
  @DocsEditable()
  final AnimatedLength cy;

  @DomName('SVGRadialGradientElement.fr')
  @DocsEditable()
  final AnimatedLength fr;

  @DomName('SVGRadialGradientElement.fx')
  @DocsEditable()
  final AnimatedLength fx;

  @DomName('SVGRadialGradientElement.fy')
  @DocsEditable()
  final AnimatedLength fy;

  @DomName('SVGRadialGradientElement.r')
  @DocsEditable()
  final AnimatedLength r;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGRect')
@Unstable()
@Native("SVGRect")
class Rect extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory Rect._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGRect.height')
  @DocsEditable()
  num height;

  @DomName('SVGRect.width')
  @DocsEditable()
  num width;

  @DomName('SVGRect.x')
  @DocsEditable()
  num x;

  @DomName('SVGRect.y')
  @DocsEditable()
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGRectElement')
@Unstable()
@Native("SVGRectElement")
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
  final AnimatedLength height;

  @DomName('SVGRectElement.rx')
  @DocsEditable()
  final AnimatedLength rx;

  @DomName('SVGRectElement.ry')
  @DocsEditable()
  final AnimatedLength ry;

  @DomName('SVGRectElement.width')
  @DocsEditable()
  final AnimatedLength width;

  @DomName('SVGRectElement.x')
  @DocsEditable()
  final AnimatedLength x;

  @DomName('SVGRectElement.y')
  @DocsEditable()
  final AnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGRenderingIntent')
@Unstable()
@Native("SVGRenderingIntent")
class RenderingIntent extends Interceptor {
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


@DocsEditable()
@DomName('SVGScriptElement')
@Unstable()
@Native("SVGScriptElement")
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
  String type;

  // From SVGURIReference

  @DomName('SVGScriptElement.href')
  @DocsEditable()
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGSetElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
@Native("SVGSetElement")
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
  static bool get supported => SvgElement.isTagSupported('set') && (new SvgElement.tag('set') is SetElement);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGStopElement')
@Unstable()
@Native("SVGStopElement")
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

  @JSName('offset')
  @DomName('SVGStopElement.offset')
  @DocsEditable()
  final AnimatedNumber gradientOffset;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGStringList')
@Unstable()
@Native("SVGStringList")
class StringList extends Interceptor with ListMixin<String>, ImmutableListMixin<String> implements List<String> {
  // To suppress missing implicit constructor warnings.
  factory StringList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGStringList.numberOfItems')
  @DocsEditable()
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
  @DocsEditable()
  String appendItem(String item) native;

  @DomName('SVGStringList.clear')
  @DocsEditable()
  void clear() native;

  @DomName('SVGStringList.getItem')
  @DocsEditable()
  String getItem(int index) native;

  @DomName('SVGStringList.initialize')
  @DocsEditable()
  String initialize(String item) native;

  @DomName('SVGStringList.insertItemBefore')
  @DocsEditable()
  String insertItemBefore(String item, int index) native;

  @DomName('SVGStringList.removeItem')
  @DocsEditable()
  String removeItem(int index) native;

  @DomName('SVGStringList.replaceItem')
  @DocsEditable()
  String replaceItem(String item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGStyleElement')
// http://www.w3.org/TR/SVG/types.html#InterfaceSVGStylable
@Experimental() // nonstandard
@Native("SVGStyleElement")
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
  bool disabled;

  @DomName('SVGStyleElement.media')
  @DocsEditable()
  String media;

  // Shadowing definition.
  String get title => JS("String", "#.title", this);

  void set title(String value) {
    JS("void", "#.title = #", this, value);
  }

  @DomName('SVGStyleElement.type')
  @DocsEditable()
  String type;
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
@Native("SVGElement")
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

  // Shadowing definition.
  AnimatedString get _svgClassName => JS("AnimatedString", "#.className", this);

  @JSName('ownerSVGElement')
  @DomName('SVGElement.ownerSVGElement')
  @DocsEditable()
  final SvgSvgElement ownerSvgElement;

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGElement.viewportElement')
  @DocsEditable()
  final SvgElement viewportElement;

  @DomName('SVGElement.xmlbase')
  @DocsEditable()
  String xmlbase;

  @DomName('SVGElement.xmllang')
  @DocsEditable()
  @Experimental() // untriaged
  String xmllang;

  @DomName('SVGElement.xmlspace')
  @DocsEditable()
  @Experimental() // untriaged
  String xmlspace;

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
@Native("SVGSVGElement")
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
  num currentScale;

  @DomName('SVGSVGElement.currentTranslate')
  @DocsEditable()
  final Point currentTranslate;

  @DomName('SVGSVGElement.currentView')
  @DocsEditable()
  final ViewSpec currentView;

  @DomName('SVGSVGElement.height')
  @DocsEditable()
  final AnimatedLength height;

  @DomName('SVGSVGElement.pixelUnitToMillimeterX')
  @DocsEditable()
  final double pixelUnitToMillimeterX;

  @DomName('SVGSVGElement.pixelUnitToMillimeterY')
  @DocsEditable()
  final double pixelUnitToMillimeterY;

  @DomName('SVGSVGElement.screenPixelToMillimeterX')
  @DocsEditable()
  final double screenPixelToMillimeterX;

  @DomName('SVGSVGElement.screenPixelToMillimeterY')
  @DocsEditable()
  final double screenPixelToMillimeterY;

  @DomName('SVGSVGElement.useCurrentView')
  @DocsEditable()
  final bool useCurrentView;

  @DomName('SVGSVGElement.viewport')
  @DocsEditable()
  final Rect viewport;

  @DomName('SVGSVGElement.width')
  @DocsEditable()
  final AnimatedLength width;

  @DomName('SVGSVGElement.x')
  @DocsEditable()
  final AnimatedLength x;

  @DomName('SVGSVGElement.y')
  @DocsEditable()
  final AnimatedLength y;

  @DomName('SVGSVGElement.animationsPaused')
  @DocsEditable()
  bool animationsPaused() native;

  @DomName('SVGSVGElement.checkEnclosure')
  @DocsEditable()
  bool checkEnclosure(SvgElement element, Rect rect) native;

  @DomName('SVGSVGElement.checkIntersection')
  @DocsEditable()
  bool checkIntersection(SvgElement element, Rect rect) native;

  @JSName('createSVGAngle')
  @DomName('SVGSVGElement.createSVGAngle')
  @DocsEditable()
  Angle createSvgAngle() native;

  @JSName('createSVGLength')
  @DomName('SVGSVGElement.createSVGLength')
  @DocsEditable()
  Length createSvgLength() native;

  @JSName('createSVGMatrix')
  @DomName('SVGSVGElement.createSVGMatrix')
  @DocsEditable()
  Matrix createSvgMatrix() native;

  @JSName('createSVGNumber')
  @DomName('SVGSVGElement.createSVGNumber')
  @DocsEditable()
  Number createSvgNumber() native;

  @JSName('createSVGPoint')
  @DomName('SVGSVGElement.createSVGPoint')
  @DocsEditable()
  Point createSvgPoint() native;

  @JSName('createSVGRect')
  @DomName('SVGSVGElement.createSVGRect')
  @DocsEditable()
  Rect createSvgRect() native;

  @JSName('createSVGTransform')
  @DomName('SVGSVGElement.createSVGTransform')
  @DocsEditable()
  Transform createSvgTransform() native;

  @JSName('createSVGTransformFromMatrix')
  @DomName('SVGSVGElement.createSVGTransformFromMatrix')
  @DocsEditable()
  Transform createSvgTransformFromMatrix(Matrix matrix) native;

  @DomName('SVGSVGElement.deselectAll')
  @DocsEditable()
  void deselectAll() native;

  @DomName('SVGSVGElement.forceRedraw')
  @DocsEditable()
  void forceRedraw() native;

  @DomName('SVGSVGElement.getCurrentTime')
  @DocsEditable()
  double getCurrentTime() native;

  @DomName('SVGSVGElement.getElementById')
  @DocsEditable()
  Element getElementById(String elementId) native;

  @DomName('SVGSVGElement.getEnclosureList')
  @DocsEditable()
  @Returns('NodeList')
  @Creates('NodeList')
  List<Node> getEnclosureList(Rect rect, SvgElement referenceElement) native;

  @DomName('SVGSVGElement.getIntersectionList')
  @DocsEditable()
  @Returns('NodeList')
  @Creates('NodeList')
  List<Node> getIntersectionList(Rect rect, SvgElement referenceElement) native;

  @DomName('SVGSVGElement.pauseAnimations')
  @DocsEditable()
  void pauseAnimations() native;

  @DomName('SVGSVGElement.setCurrentTime')
  @DocsEditable()
  void setCurrentTime(num seconds) native;

  @DomName('SVGSVGElement.suspendRedraw')
  @DocsEditable()
  int suspendRedraw(int maxWaitMilliseconds) native;

  @DomName('SVGSVGElement.unpauseAnimations')
  @DocsEditable()
  void unpauseAnimations() native;

  @DomName('SVGSVGElement.unsuspendRedraw')
  @DocsEditable()
  void unsuspendRedraw(int suspendHandleId) native;

  @DomName('SVGSVGElement.unsuspendRedrawAll')
  @DocsEditable()
  void unsuspendRedrawAll() native;

  // From SVGFitToViewBox

  @DomName('SVGSVGElement.preserveAspectRatio')
  @DocsEditable()
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  @DomName('SVGSVGElement.viewBox')
  @DocsEditable()
  final AnimatedRect viewBox;

  // From SVGZoomAndPan

  @DomName('SVGSVGElement.zoomAndPan')
  @DocsEditable()
  int zoomAndPan;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGSwitchElement')
@Unstable()
@Native("SVGSwitchElement")
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


@DocsEditable()
@DomName('SVGSymbolElement')
@Unstable()
@Native("SVGSymbolElement")
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

  // From SVGFitToViewBox

  @DomName('SVGSymbolElement.preserveAspectRatio')
  @DocsEditable()
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  @DomName('SVGSymbolElement.viewBox')
  @DocsEditable()
  final AnimatedRect viewBox;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGTSpanElement')
@Unstable()
@Native("SVGTSpanElement")
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


@DocsEditable()
@DomName('SVGTests')
@Unstable()
abstract class Tests extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory Tests._() { throw new UnsupportedError("Not supported"); }

  final StringList requiredExtensions;

  final StringList requiredFeatures;

  final StringList systemLanguage;

  bool hasExtension(String extension);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGTextContentElement')
@Unstable()
@Native("SVGTextContentElement")
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
  final AnimatedEnumeration lengthAdjust;

  @DomName('SVGTextContentElement.textLength')
  @DocsEditable()
  final AnimatedLength textLength;

  @DomName('SVGTextContentElement.getCharNumAtPosition')
  @DocsEditable()
  int getCharNumAtPosition(Point point) native;

  @DomName('SVGTextContentElement.getComputedTextLength')
  @DocsEditable()
  double getComputedTextLength() native;

  @DomName('SVGTextContentElement.getEndPositionOfChar')
  @DocsEditable()
  Point getEndPositionOfChar(int offset) native;

  @DomName('SVGTextContentElement.getExtentOfChar')
  @DocsEditable()
  Rect getExtentOfChar(int offset) native;

  @DomName('SVGTextContentElement.getNumberOfChars')
  @DocsEditable()
  int getNumberOfChars() native;

  @DomName('SVGTextContentElement.getRotationOfChar')
  @DocsEditable()
  double getRotationOfChar(int offset) native;

  @DomName('SVGTextContentElement.getStartPositionOfChar')
  @DocsEditable()
  Point getStartPositionOfChar(int offset) native;

  @DomName('SVGTextContentElement.getSubStringLength')
  @DocsEditable()
  double getSubStringLength(int offset, int length) native;

  @DomName('SVGTextContentElement.selectSubString')
  @DocsEditable()
  void selectSubString(int offset, int length) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGTextElement')
@Unstable()
@Native("SVGTextElement")
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


@DocsEditable()
@DomName('SVGTextPathElement')
@Unstable()
@Native("SVGTextPathElement")
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
  final AnimatedEnumeration method;

  @DomName('SVGTextPathElement.spacing')
  @DocsEditable()
  final AnimatedEnumeration spacing;

  @DomName('SVGTextPathElement.startOffset')
  @DocsEditable()
  final AnimatedLength startOffset;

  // From SVGURIReference

  @DomName('SVGTextPathElement.href')
  @DocsEditable()
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGTextPositioningElement')
@Unstable()
@Native("SVGTextPositioningElement")
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
  final AnimatedLengthList dx;

  @DomName('SVGTextPositioningElement.dy')
  @DocsEditable()
  final AnimatedLengthList dy;

  @DomName('SVGTextPositioningElement.rotate')
  @DocsEditable()
  final AnimatedNumberList rotate;

  @DomName('SVGTextPositioningElement.x')
  @DocsEditable()
  final AnimatedLengthList x;

  @DomName('SVGTextPositioningElement.y')
  @DocsEditable()
  final AnimatedLengthList y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGTitleElement')
@Unstable()
@Native("SVGTitleElement")
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


@DocsEditable()
@DomName('SVGTransform')
@Unstable()
@Native("SVGTransform")
class Transform extends Interceptor {
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
  final double angle;

  @DomName('SVGTransform.matrix')
  @DocsEditable()
  final Matrix matrix;

  @DomName('SVGTransform.type')
  @DocsEditable()
  final int type;

  @DomName('SVGTransform.setMatrix')
  @DocsEditable()
  void setMatrix(Matrix matrix) native;

  @DomName('SVGTransform.setRotate')
  @DocsEditable()
  void setRotate(num angle, num cx, num cy) native;

  @DomName('SVGTransform.setScale')
  @DocsEditable()
  void setScale(num sx, num sy) native;

  @DomName('SVGTransform.setSkewX')
  @DocsEditable()
  void setSkewX(num angle) native;

  @DomName('SVGTransform.setSkewY')
  @DocsEditable()
  void setSkewY(num angle) native;

  @DomName('SVGTransform.setTranslate')
  @DocsEditable()
  void setTranslate(num tx, num ty) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGTransformList')
@Unstable()
@Native("SVGTransformList")
class TransformList extends Interceptor with ListMixin<Transform>, ImmutableListMixin<Transform> implements List<Transform> {
  // To suppress missing implicit constructor warnings.
  factory TransformList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGTransformList.numberOfItems')
  @DocsEditable()
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
  @DocsEditable()
  Transform appendItem(Transform item) native;

  @DomName('SVGTransformList.clear')
  @DocsEditable()
  void clear() native;

  @DomName('SVGTransformList.consolidate')
  @DocsEditable()
  Transform consolidate() native;

  @JSName('createSVGTransformFromMatrix')
  @DomName('SVGTransformList.createSVGTransformFromMatrix')
  @DocsEditable()
  Transform createSvgTransformFromMatrix(Matrix matrix) native;

  @DomName('SVGTransformList.getItem')
  @DocsEditable()
  Transform getItem(int index) native;

  @DomName('SVGTransformList.initialize')
  @DocsEditable()
  Transform initialize(Transform item) native;

  @DomName('SVGTransformList.insertItemBefore')
  @DocsEditable()
  Transform insertItemBefore(Transform item, int index) native;

  @DomName('SVGTransformList.removeItem')
  @DocsEditable()
  Transform removeItem(int index) native;

  @DomName('SVGTransformList.replaceItem')
  @DocsEditable()
  Transform replaceItem(Transform item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGUnitTypes')
@Unstable()
@Native("SVGUnitTypes")
class UnitTypes extends Interceptor {
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


@DocsEditable()
@DomName('SVGURIReference')
@Unstable()
abstract class UriReference extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory UriReference._() { throw new UnsupportedError("Not supported"); }

  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGUseElement')
@Unstable()
@Native("SVGUseElement")
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
  final ElementInstance animatedInstanceRoot;

  @DomName('SVGUseElement.height')
  @DocsEditable()
  final AnimatedLength height;

  @DomName('SVGUseElement.instanceRoot')
  @DocsEditable()
  final ElementInstance instanceRoot;

  @DomName('SVGUseElement.width')
  @DocsEditable()
  final AnimatedLength width;

  @DomName('SVGUseElement.x')
  @DocsEditable()
  final AnimatedLength x;

  @DomName('SVGUseElement.y')
  @DocsEditable()
  final AnimatedLength y;

  // From SVGTests

  @DomName('SVGUseElement.requiredExtensions')
  @DocsEditable()
  final StringList requiredExtensions;

  @DomName('SVGUseElement.requiredFeatures')
  @DocsEditable()
  final StringList requiredFeatures;

  @DomName('SVGUseElement.systemLanguage')
  @DocsEditable()
  final StringList systemLanguage;

  @DomName('SVGUseElement.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) native;

  // From SVGURIReference

  @DomName('SVGUseElement.href')
  @DocsEditable()
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGViewElement')
@Unstable()
@Native("SVGViewElement")
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
  final StringList viewTarget;

  // From SVGFitToViewBox

  @DomName('SVGViewElement.preserveAspectRatio')
  @DocsEditable()
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  @DomName('SVGViewElement.viewBox')
  @DocsEditable()
  final AnimatedRect viewBox;

  // From SVGZoomAndPan

  @DomName('SVGViewElement.zoomAndPan')
  @DocsEditable()
  int zoomAndPan;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGViewSpec')
@Unstable()
@Native("SVGViewSpec")
class ViewSpec extends Interceptor implements FitToViewBox, ZoomAndPan {
  // To suppress missing implicit constructor warnings.
  factory ViewSpec._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGViewSpec.preserveAspectRatioString')
  @DocsEditable()
  final String preserveAspectRatioString;

  @DomName('SVGViewSpec.transform')
  @DocsEditable()
  final TransformList transform;

  @DomName('SVGViewSpec.transformString')
  @DocsEditable()
  final String transformString;

  @DomName('SVGViewSpec.viewBoxString')
  @DocsEditable()
  final String viewBoxString;

  @DomName('SVGViewSpec.viewTarget')
  @DocsEditable()
  final SvgElement viewTarget;

  @DomName('SVGViewSpec.viewTargetString')
  @DocsEditable()
  final String viewTargetString;

  // From SVGFitToViewBox

  @DomName('SVGViewSpec.preserveAspectRatio')
  @DocsEditable()
  @Experimental() // nonstandard
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  @DomName('SVGViewSpec.viewBox')
  @DocsEditable()
  @Experimental() // nonstandard
  final AnimatedRect viewBox;

  // From SVGZoomAndPan

  @DomName('SVGViewSpec.zoomAndPan')
  @DocsEditable()
  @Experimental() // nonstandard
  int zoomAndPan;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGZoomAndPan')
@Unstable()
abstract class ZoomAndPan extends Interceptor {
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

  int zoomAndPan;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGZoomEvent')
@Unstable()
@Native("SVGZoomEvent")
class ZoomEvent extends UIEvent {
  // To suppress missing implicit constructor warnings.
  factory ZoomEvent._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGZoomEvent.newScale')
  @DocsEditable()
  final double newScale;

  @DomName('SVGZoomEvent.newTranslate')
  @DocsEditable()
  final Point newTranslate;

  @DomName('SVGZoomEvent.previousScale')
  @DocsEditable()
  final double previousScale;

  @DomName('SVGZoomEvent.previousTranslate')
  @DocsEditable()
  final Point previousTranslate;

  @DomName('SVGZoomEvent.zoomRectScreen')
  @DocsEditable()
  final Rect zoomRectScreen;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGElementInstanceList')
@Unstable()
@Native("SVGElementInstanceList")
class _ElementInstanceList extends Interceptor with ListMixin<ElementInstance>, ImmutableListMixin<ElementInstance> implements List<ElementInstance> {
  // To suppress missing implicit constructor warnings.
  factory _ElementInstanceList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGElementInstanceList.length')
  @DocsEditable()
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
  @DocsEditable()
  ElementInstance item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGGradientElement')
@Unstable()
@Native("SVGGradientElement")
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
  final AnimatedTransformList gradientTransform;

  @DomName('SVGGradientElement.gradientUnits')
  @DocsEditable()
  final AnimatedEnumeration gradientUnits;

  @DomName('SVGGradientElement.spreadMethod')
  @DocsEditable()
  final AnimatedEnumeration spreadMethod;

  // From SVGURIReference

  @DomName('SVGGradientElement.href')
  @DocsEditable()
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGAltGlyphDefElement')
@Unstable()
@Native("SVGAltGlyphDefElement")
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


@DocsEditable()
@DomName('SVGAltGlyphItemElement')
@Unstable()
@Native("SVGAltGlyphItemElement")
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


@DocsEditable()
@DomName('SVGComponentTransferFunctionElement')
@Unstable()
@Native("SVGComponentTransferFunctionElement")
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


@DocsEditable()
@DomName('SVGCursorElement')
@Unstable()
@Native("SVGCursorElement")
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
  static bool get supported => SvgElement.isTagSupported('cursor') && (new SvgElement.tag('cursor') is _SVGCursorElement);

  // From SVGTests

  // From SVGURIReference
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFEDropShadowElement')
@Experimental() // nonstandard
@Native("SVGFEDropShadowElement")
abstract class _SVGFEDropShadowElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory _SVGFEDropShadowElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGFEDropShadowElement.created() : super.created();

  // From SVGFilterPrimitiveStandardAttributes
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGFontElement')
@Unstable()
@Native("SVGFontElement")
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


@DocsEditable()
@DomName('SVGFontFaceElement')
@Unstable()
@Native("SVGFontFaceElement")
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


@DocsEditable()
@DomName('SVGFontFaceFormatElement')
@Unstable()
@Native("SVGFontFaceFormatElement")
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


@DocsEditable()
@DomName('SVGFontFaceNameElement')
@Unstable()
@Native("SVGFontFaceNameElement")
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


@DocsEditable()
@DomName('SVGFontFaceSrcElement')
@Unstable()
@Native("SVGFontFaceSrcElement")
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


@DocsEditable()
@DomName('SVGFontFaceUriElement')
@Unstable()
@Native("SVGFontFaceUriElement")
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


@DocsEditable()
@DomName('SVGGlyphElement')
@Unstable()
@Native("SVGGlyphElement")
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


@DocsEditable()
@DomName('SVGGlyphRefElement')
@Unstable()
@Native("SVGGlyphRefElement")
abstract class _SVGGlyphRefElement extends SvgElement implements UriReference {
  // To suppress missing implicit constructor warnings.
  factory _SVGGlyphRefElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGGlyphRefElement.created() : super.created();

  // From SVGURIReference
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGHKernElement')
@Unstable()
@Native("SVGHKernElement")
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


@DocsEditable()
@DomName('SVGMPathElement')
@Native("SVGMPathElement")
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

  // From SVGURIReference
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SVGMissingGlyphElement')
@Unstable()
@Native("SVGMissingGlyphElement")
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


@DocsEditable()
@DomName('SVGVKernElement')
@Unstable()
@Native("SVGVKernElement")
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
