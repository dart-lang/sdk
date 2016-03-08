dart_library.library('dart/svg', null, /* Imports */[
  'dart/_runtime',
  'dart/html',
  'dart/core',
  'dart/html_common',
  'dart/_metadata',
  'dart/_js_helper',
  'dart/_interceptors',
  'dart/collection'
], /* Lazy imports */[
], function(exports, dart, html$, core, html_common, _metadata, _js_helper, _interceptors, collection) {
  'use strict';
  let dartx = dart.dartx;
  class _SvgElementFactoryProvider extends core.Object {
    static createSvgElement_tag(tag) {
      let temp = html$.document[dartx.createElementNS]("http://www.w3.org/2000/svg", tag);
      return dart.as(temp, SvgElement);
    }
  }
  dart.setSignature(_SvgElementFactoryProvider, {
    statics: () => ({createSvgElement_tag: [SvgElement, [core.String]]}),
    names: ['createSvgElement_tag']
  });
  const _children = Symbol('_children');
  const _svgClassName = Symbol('_svgClassName');
  dart.defineExtensionNames([
    'classes',
    'children',
    'children',
    'outerHtml',
    'innerHtml',
    'innerHtml',
    'createFragment',
    'insertAdjacentText',
    'insertAdjacentHtml',
    'insertAdjacentElement',
    'isContentEditable',
    'click',
    'tabIndex',
    'tabIndex',
    'onAbort',
    'onBlur',
    'onCanPlay',
    'onCanPlayThrough',
    'onChange',
    'onClick',
    'onContextMenu',
    'onDoubleClick',
    'onDrag',
    'onDragEnd',
    'onDragEnter',
    'onDragLeave',
    'onDragOver',
    'onDragStart',
    'onDrop',
    'onDurationChange',
    'onEmptied',
    'onEnded',
    'onError',
    'onFocus',
    'onInput',
    'onInvalid',
    'onKeyDown',
    'onKeyPress',
    'onKeyUp',
    'onLoad',
    'onLoadedData',
    'onLoadedMetadata',
    'onMouseDown',
    'onMouseEnter',
    'onMouseLeave',
    'onMouseMove',
    'onMouseOut',
    'onMouseOver',
    'onMouseUp',
    'onMouseWheel',
    'onPause',
    'onPlay',
    'onPlaying',
    'onRateChange',
    'onReset',
    'onResize',
    'onScroll',
    'onSeeked',
    'onSeeking',
    'onSelect',
    'onStalled',
    'onSubmit',
    'onSuspend',
    'onTimeUpdate',
    'onVolumeChange',
    'onWaiting',
    'ownerSvgElement',
    'viewportElement',
    'xmlbase',
    'xmllang',
    'xmlspace'
  ]);
  class SvgElement extends html$.Element {
    static tag(tag) {
      return dart.as(html$.document[dartx.createElementNS]("http://www.w3.org/2000/svg", tag), SvgElement);
    }
    static svg(svg, opts) {
      let validator = opts && 'validator' in opts ? opts.validator : null;
      let treeSanitizer = opts && 'treeSanitizer' in opts ? opts.treeSanitizer : null;
      if (validator == null && treeSanitizer == null) {
        validator = new html$.NodeValidatorBuilder.common();
        validator.allowSvg();
      }
      let match = SvgElement._START_TAG_REGEXP.firstMatch(svg);
      let parentElement = null;
      if (match != null && match.group(1)[dartx.toLowerCase]() == 'svg') {
        parentElement = html$.document[dartx.body];
      } else {
        parentElement = SvgSvgElement.new();
      }
      let fragment = dart.dsend(parentElement, 'createFragment', svg, {validator: validator, treeSanitizer: treeSanitizer});
      return dart.as(dart.dload(dart.dsend(dart.dload(fragment, 'nodes'), 'where', dart.fn(e => dart.is(e, SvgElement), core.bool, [dart.dynamic])), 'single'), SvgElement);
    }
    get [dartx.classes]() {
      return new _AttributeClassSet(this);
    }
    get [dartx.children]() {
      return new html_common.FilteredElementList(this);
    }
    set [dartx.children](value) {
      let children = this[dartx.children];
      children[dartx.clear]();
      children[dartx.addAll](value);
    }
    get [dartx.outerHtml]() {
      let container = html$.Element.tag("div");
      let cloned = dart.as(this[dartx.clone](true), SvgElement);
      container[dartx.children][dartx.add](cloned);
      return container[dartx.innerHtml];
    }
    get [dartx.innerHtml]() {
      let container = html$.Element.tag("div");
      let cloned = dart.as(this[dartx.clone](true), SvgElement);
      container[dartx.children][dartx.addAll](cloned[dartx.children]);
      return container[dartx.innerHtml];
    }
    set [dartx.innerHtml](value) {
      this[dartx.setInnerHtml](value);
    }
    [dartx.createFragment](svg, opts) {
      let validator = opts && 'validator' in opts ? opts.validator : null;
      let treeSanitizer = opts && 'treeSanitizer' in opts ? opts.treeSanitizer : null;
      if (treeSanitizer == null) {
        if (validator == null) {
          validator = new html$.NodeValidatorBuilder.common();
          validator.allowSvg();
        }
        treeSanitizer = html$.NodeTreeSanitizer.new(validator);
      }
      let html = `<svg version="1.1">${svg}</svg>`;
      let fragment = html$.document[dartx.body][dartx.createFragment](html, {treeSanitizer: treeSanitizer});
      let svgFragment = html$.DocumentFragment.new();
      let root = fragment[dartx.nodes][dartx.single];
      while (root[dartx.firstChild] != null) {
        svgFragment[dartx.append](root[dartx.firstChild]);
      }
      return svgFragment;
    }
    [dartx.insertAdjacentText](where, text) {
      dart.throw(new core.UnsupportedError("Cannot invoke insertAdjacentText on SVG."));
    }
    [dartx.insertAdjacentHtml](where, text, opts) {
      let validator = opts && 'validator' in opts ? opts.validator : null;
      let treeSanitizer = opts && 'treeSanitizer' in opts ? opts.treeSanitizer : null;
      dart.throw(new core.UnsupportedError("Cannot invoke insertAdjacentHtml on SVG."));
    }
    [dartx.insertAdjacentElement](where, element) {
      dart.throw(new core.UnsupportedError("Cannot invoke insertAdjacentElement on SVG."));
    }
    get [_children]() {
      dart.throw(new core.UnsupportedError("Cannot get _children on SVG."));
    }
    get [dartx.isContentEditable]() {
      return false;
    }
    [dartx.click]() {
      dart.throw(new core.UnsupportedError("Cannot invoke click SVG."));
    }
    static isTagSupported(tag) {
      let e = SvgElement.tag(tag);
      return dart.is(e, SvgElement) && !dart.is(e, html$.UnknownElement);
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      this[dartx.ownerSvgElement] = null;
      this[dartx.viewportElement] = null;
      this[dartx.xmlbase] = null;
      this[dartx.xmllang] = null;
      this[dartx.xmlspace] = null;
      super.created();
    }
    get [_svgClassName]() {
      return dart.as(this.className, AnimatedString);
    }
    get [dartx.ownerSvgElement]() {
      return this.ownerSVGElement;
    }
    get [dartx.tabIndex]() {
      return this.tabIndex;
    }
    set [dartx.tabIndex](value) {
      this.tabIndex = value;
    }
    get [dartx.viewportElement]() {
      return this.viewportElement;
    }
    get [dartx.xmlbase]() {
      return this.xmlbase;
    }
    set [dartx.xmlbase](value) {
      this.xmlbase = value;
    }
    get [dartx.xmllang]() {
      return this.xmllang;
    }
    set [dartx.xmllang](value) {
      this.xmllang = value;
    }
    get [dartx.xmlspace]() {
      return this.xmlspace;
    }
    set [dartx.xmlspace](value) {
      this.xmlspace = value;
    }
    get [dartx.onAbort]() {
      return html$.Element.abortEvent.forElement(this);
    }
    get [dartx.onBlur]() {
      return html$.Element.blurEvent.forElement(this);
    }
    get [dartx.onCanPlay]() {
      return html$.Element.canPlayEvent.forElement(this);
    }
    get [dartx.onCanPlayThrough]() {
      return html$.Element.canPlayThroughEvent.forElement(this);
    }
    get [dartx.onChange]() {
      return html$.Element.changeEvent.forElement(this);
    }
    get [dartx.onClick]() {
      return html$.Element.clickEvent.forElement(this);
    }
    get [dartx.onContextMenu]() {
      return html$.Element.contextMenuEvent.forElement(this);
    }
    get [dartx.onDoubleClick]() {
      return html$.Element.doubleClickEvent.forElement(this);
    }
    get [dartx.onDrag]() {
      return html$.Element.dragEvent.forElement(this);
    }
    get [dartx.onDragEnd]() {
      return html$.Element.dragEndEvent.forElement(this);
    }
    get [dartx.onDragEnter]() {
      return html$.Element.dragEnterEvent.forElement(this);
    }
    get [dartx.onDragLeave]() {
      return html$.Element.dragLeaveEvent.forElement(this);
    }
    get [dartx.onDragOver]() {
      return html$.Element.dragOverEvent.forElement(this);
    }
    get [dartx.onDragStart]() {
      return html$.Element.dragStartEvent.forElement(this);
    }
    get [dartx.onDrop]() {
      return html$.Element.dropEvent.forElement(this);
    }
    get [dartx.onDurationChange]() {
      return html$.Element.durationChangeEvent.forElement(this);
    }
    get [dartx.onEmptied]() {
      return html$.Element.emptiedEvent.forElement(this);
    }
    get [dartx.onEnded]() {
      return html$.Element.endedEvent.forElement(this);
    }
    get [dartx.onError]() {
      return html$.Element.errorEvent.forElement(this);
    }
    get [dartx.onFocus]() {
      return html$.Element.focusEvent.forElement(this);
    }
    get [dartx.onInput]() {
      return html$.Element.inputEvent.forElement(this);
    }
    get [dartx.onInvalid]() {
      return html$.Element.invalidEvent.forElement(this);
    }
    get [dartx.onKeyDown]() {
      return html$.Element.keyDownEvent.forElement(this);
    }
    get [dartx.onKeyPress]() {
      return html$.Element.keyPressEvent.forElement(this);
    }
    get [dartx.onKeyUp]() {
      return html$.Element.keyUpEvent.forElement(this);
    }
    get [dartx.onLoad]() {
      return html$.Element.loadEvent.forElement(this);
    }
    get [dartx.onLoadedData]() {
      return html$.Element.loadedDataEvent.forElement(this);
    }
    get [dartx.onLoadedMetadata]() {
      return html$.Element.loadedMetadataEvent.forElement(this);
    }
    get [dartx.onMouseDown]() {
      return html$.Element.mouseDownEvent.forElement(this);
    }
    get [dartx.onMouseEnter]() {
      return html$.Element.mouseEnterEvent.forElement(this);
    }
    get [dartx.onMouseLeave]() {
      return html$.Element.mouseLeaveEvent.forElement(this);
    }
    get [dartx.onMouseMove]() {
      return html$.Element.mouseMoveEvent.forElement(this);
    }
    get [dartx.onMouseOut]() {
      return html$.Element.mouseOutEvent.forElement(this);
    }
    get [dartx.onMouseOver]() {
      return html$.Element.mouseOverEvent.forElement(this);
    }
    get [dartx.onMouseUp]() {
      return html$.Element.mouseUpEvent.forElement(this);
    }
    get [dartx.onMouseWheel]() {
      return html$.Element.mouseWheelEvent.forElement(this);
    }
    get [dartx.onPause]() {
      return html$.Element.pauseEvent.forElement(this);
    }
    get [dartx.onPlay]() {
      return html$.Element.playEvent.forElement(this);
    }
    get [dartx.onPlaying]() {
      return html$.Element.playingEvent.forElement(this);
    }
    get [dartx.onRateChange]() {
      return html$.Element.rateChangeEvent.forElement(this);
    }
    get [dartx.onReset]() {
      return html$.Element.resetEvent.forElement(this);
    }
    get [dartx.onResize]() {
      return html$.Element.resizeEvent.forElement(this);
    }
    get [dartx.onScroll]() {
      return html$.Element.scrollEvent.forElement(this);
    }
    get [dartx.onSeeked]() {
      return html$.Element.seekedEvent.forElement(this);
    }
    get [dartx.onSeeking]() {
      return html$.Element.seekingEvent.forElement(this);
    }
    get [dartx.onSelect]() {
      return html$.Element.selectEvent.forElement(this);
    }
    get [dartx.onStalled]() {
      return html$.Element.stalledEvent.forElement(this);
    }
    get [dartx.onSubmit]() {
      return html$.Element.submitEvent.forElement(this);
    }
    get [dartx.onSuspend]() {
      return html$.Element.suspendEvent.forElement(this);
    }
    get [dartx.onTimeUpdate]() {
      return html$.Element.timeUpdateEvent.forElement(this);
    }
    get [dartx.onVolumeChange]() {
      return html$.Element.volumeChangeEvent.forElement(this);
    }
    get [dartx.onWaiting]() {
      return html$.Element.waitingEvent.forElement(this);
    }
  }
  SvgElement[dart.implements] = () => [html$.GlobalEventHandlers];
  dart.defineNamedConstructor(SvgElement, 'created');
  dart.setSignature(SvgElement, {
    constructors: () => ({
      tag: [SvgElement, [core.String]],
      svg: [SvgElement, [core.String], {validator: html$.NodeValidator, treeSanitizer: html$.NodeTreeSanitizer}],
      _: [SvgElement, []],
      created: [SvgElement, []]
    })
  });
  SvgElement[dart.metadata] = () => [dart.const(new _metadata.DomName('SVGElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGElement"))];
  dart.defineLazyProperties(SvgElement, {
    get _START_TAG_REGEXP() {
      return core.RegExp.new('<(\\w+)');
    }
  });
  dart.registerExtension(dart.global.SVGElement, SvgElement);
  dart.defineExtensionNames([
    'getBBox',
    'getCtm',
    'getScreenCtm',
    'getTransformToElement',
    'hasExtension',
    'farthestViewportElement',
    'nearestViewportElement',
    'transform',
    'requiredExtensions',
    'requiredFeatures',
    'systemLanguage'
  ]);
  class GraphicsElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      this[dartx.farthestViewportElement] = null;
      this[dartx.nearestViewportElement] = null;
      this[dartx.transform] = null;
      this[dartx.requiredExtensions] = null;
      this[dartx.requiredFeatures] = null;
      this[dartx.systemLanguage] = null;
      super.created();
    }
    get [dartx.farthestViewportElement]() {
      return this.farthestViewportElement;
    }
    get [dartx.nearestViewportElement]() {
      return this.nearestViewportElement;
    }
    get [dartx.transform]() {
      return this.transform;
    }
    [dartx.getBBox]() {
      return this.getBBox();
    }
    [dartx.getCtm]() {
      return this.getCTM();
    }
    [dartx.getScreenCtm]() {
      return this.getScreenCTM();
    }
    [dartx.getTransformToElement](element) {
      return this.getTransformToElement(element);
    }
    get [dartx.requiredExtensions]() {
      return this.requiredExtensions;
    }
    get [dartx.requiredFeatures]() {
      return this.requiredFeatures;
    }
    get [dartx.systemLanguage]() {
      return this.systemLanguage;
    }
    [dartx.hasExtension](extension) {
      return this.hasExtension(extension);
    }
  }
  GraphicsElement[dart.implements] = () => [Tests];
  dart.defineNamedConstructor(GraphicsElement, 'created');
  dart.setSignature(GraphicsElement, {
    constructors: () => ({
      _: [GraphicsElement, []],
      created: [GraphicsElement, []]
    }),
    methods: () => ({
      [dartx.getBBox]: [Rect, []],
      [dartx.getCtm]: [Matrix, []],
      [dartx.getScreenCtm]: [Matrix, []],
      [dartx.getTransformToElement]: [Matrix, [SvgElement]],
      [dartx.hasExtension]: [core.bool, [core.String]]
    })
  });
  GraphicsElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGGraphicsElement')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("SVGGraphicsElement"))];
  dart.registerExtension(dart.global.SVGGraphicsElement, GraphicsElement);
  dart.defineExtensionNames([
    'target',
    'href'
  ]);
  class AElement extends GraphicsElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("a"), AElement);
    }
    created() {
      this[dartx.target] = null;
      this[dartx.href] = null;
      super.created();
    }
    get [dartx.target]() {
      return this.target;
    }
    get [dartx.href]() {
      return this.href;
    }
  }
  AElement[dart.implements] = () => [UriReference];
  dart.defineNamedConstructor(AElement, 'created');
  dart.setSignature(AElement, {
    constructors: () => ({
      _: [AElement, []],
      new: [AElement, []],
      created: [AElement, []]
    })
  });
  AElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGAElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGAElement"))];
  dart.registerExtension(dart.global.SVGAElement, AElement);
  dart.defineExtensionNames([
    'getCharNumAtPosition',
    'getComputedTextLength',
    'getEndPositionOfChar',
    'getExtentOfChar',
    'getNumberOfChars',
    'getRotationOfChar',
    'getStartPositionOfChar',
    'getSubStringLength',
    'selectSubString',
    'lengthAdjust',
    'textLength'
  ]);
  class TextContentElement extends GraphicsElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      this[dartx.lengthAdjust] = null;
      this[dartx.textLength] = null;
      super.created();
    }
    get [dartx.lengthAdjust]() {
      return this.lengthAdjust;
    }
    get [dartx.textLength]() {
      return this.textLength;
    }
    [dartx.getCharNumAtPosition](point) {
      return this.getCharNumAtPosition(point);
    }
    [dartx.getComputedTextLength]() {
      return this.getComputedTextLength();
    }
    [dartx.getEndPositionOfChar](offset) {
      return this.getEndPositionOfChar(offset);
    }
    [dartx.getExtentOfChar](offset) {
      return this.getExtentOfChar(offset);
    }
    [dartx.getNumberOfChars]() {
      return this.getNumberOfChars();
    }
    [dartx.getRotationOfChar](offset) {
      return this.getRotationOfChar(offset);
    }
    [dartx.getStartPositionOfChar](offset) {
      return this.getStartPositionOfChar(offset);
    }
    [dartx.getSubStringLength](offset, length) {
      return this.getSubStringLength(offset, length);
    }
    [dartx.selectSubString](offset, length) {
      return this.selectSubString(offset, length);
    }
  }
  dart.defineNamedConstructor(TextContentElement, 'created');
  dart.setSignature(TextContentElement, {
    constructors: () => ({
      _: [TextContentElement, []],
      created: [TextContentElement, []]
    }),
    methods: () => ({
      [dartx.getCharNumAtPosition]: [core.int, [Point]],
      [dartx.getComputedTextLength]: [core.double, []],
      [dartx.getEndPositionOfChar]: [Point, [core.int]],
      [dartx.getExtentOfChar]: [Rect, [core.int]],
      [dartx.getNumberOfChars]: [core.int, []],
      [dartx.getRotationOfChar]: [core.double, [core.int]],
      [dartx.getStartPositionOfChar]: [Point, [core.int]],
      [dartx.getSubStringLength]: [core.double, [core.int, core.int]],
      [dartx.selectSubString]: [dart.void, [core.int, core.int]]
    })
  });
  TextContentElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGTextContentElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGTextContentElement"))];
  TextContentElement.LENGTHADJUST_SPACING = 1;
  TextContentElement.LENGTHADJUST_SPACINGANDGLYPHS = 2;
  TextContentElement.LENGTHADJUST_UNKNOWN = 0;
  dart.registerExtension(dart.global.SVGTextContentElement, TextContentElement);
  dart.defineExtensionNames([
    'dx',
    'dy',
    'rotate',
    'x',
    'y'
  ]);
  class TextPositioningElement extends TextContentElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      this[dartx.dx] = null;
      this[dartx.dy] = null;
      this[dartx.rotate] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      super.created();
    }
    get [dartx.dx]() {
      return this.dx;
    }
    get [dartx.dy]() {
      return this.dy;
    }
    get [dartx.rotate]() {
      return this.rotate;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
  }
  dart.defineNamedConstructor(TextPositioningElement, 'created');
  dart.setSignature(TextPositioningElement, {
    constructors: () => ({
      _: [TextPositioningElement, []],
      created: [TextPositioningElement, []]
    })
  });
  TextPositioningElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGTextPositioningElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGTextPositioningElement"))];
  dart.registerExtension(dart.global.SVGTextPositioningElement, TextPositioningElement);
  dart.defineExtensionNames([
    'format',
    'glyphRef',
    'href'
  ]);
  class AltGlyphElement extends TextPositioningElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("altGlyph"), AltGlyphElement);
    }
    created() {
      this[dartx.format] = null;
      this[dartx.glyphRef] = null;
      this[dartx.href] = null;
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('altGlyph')) && dart.is(SvgElement.tag('altGlyph'), AltGlyphElement);
    }
    get [dartx.format]() {
      return this.format;
    }
    set [dartx.format](value) {
      this.format = value;
    }
    get [dartx.glyphRef]() {
      return this.glyphRef;
    }
    set [dartx.glyphRef](value) {
      this.glyphRef = value;
    }
    get [dartx.href]() {
      return this.href;
    }
  }
  AltGlyphElement[dart.implements] = () => [UriReference];
  dart.defineNamedConstructor(AltGlyphElement, 'created');
  dart.setSignature(AltGlyphElement, {
    constructors: () => ({
      _: [AltGlyphElement, []],
      new: [AltGlyphElement, []],
      created: [AltGlyphElement, []]
    })
  });
  AltGlyphElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGAltGlyphElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGAltGlyphElement"))];
  dart.registerExtension(dart.global.SVGAltGlyphElement, AltGlyphElement);
  dart.defineExtensionNames([
    'convertToSpecifiedUnits',
    'newValueSpecifiedUnits',
    'unitType',
    'value',
    'valueAsString',
    'valueInSpecifiedUnits'
  ]);
  class Angle extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.unitType]() {
      return this.unitType;
    }
    get [dartx.value]() {
      return this.value;
    }
    set [dartx.value](value) {
      this.value = value;
    }
    get [dartx.valueAsString]() {
      return this.valueAsString;
    }
    set [dartx.valueAsString](value) {
      this.valueAsString = value;
    }
    get [dartx.valueInSpecifiedUnits]() {
      return this.valueInSpecifiedUnits;
    }
    set [dartx.valueInSpecifiedUnits](value) {
      this.valueInSpecifiedUnits = value;
    }
    [dartx.convertToSpecifiedUnits](unitType) {
      return this.convertToSpecifiedUnits(unitType);
    }
    [dartx.newValueSpecifiedUnits](unitType, valueInSpecifiedUnits) {
      return this.newValueSpecifiedUnits(unitType, valueInSpecifiedUnits);
    }
  }
  dart.setSignature(Angle, {
    constructors: () => ({_: [Angle, []]}),
    methods: () => ({
      [dartx.convertToSpecifiedUnits]: [dart.void, [core.int]],
      [dartx.newValueSpecifiedUnits]: [dart.void, [core.int, core.num]]
    })
  });
  Angle[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGAngle')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGAngle"))];
  Angle.SVG_ANGLETYPE_DEG = 2;
  Angle.SVG_ANGLETYPE_GRAD = 4;
  Angle.SVG_ANGLETYPE_RAD = 3;
  Angle.SVG_ANGLETYPE_UNKNOWN = 0;
  Angle.SVG_ANGLETYPE_UNSPECIFIED = 1;
  dart.registerExtension(dart.global.SVGAngle, Angle);
  dart.defineExtensionNames([
    'beginElement',
    'beginElementAt',
    'endElement',
    'endElementAt',
    'getCurrentTime',
    'getSimpleDuration',
    'getStartTime',
    'hasExtension',
    'targetElement',
    'requiredExtensions',
    'requiredFeatures',
    'systemLanguage'
  ]);
  class AnimationElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("animation"), AnimationElement);
    }
    created() {
      this[dartx.targetElement] = null;
      this[dartx.requiredExtensions] = null;
      this[dartx.requiredFeatures] = null;
      this[dartx.systemLanguage] = null;
      super.created();
    }
    get [dartx.targetElement]() {
      return this.targetElement;
    }
    [dartx.beginElement]() {
      return this.beginElement();
    }
    [dartx.beginElementAt](offset) {
      return this.beginElementAt(offset);
    }
    [dartx.endElement]() {
      return this.endElement();
    }
    [dartx.endElementAt](offset) {
      return this.endElementAt(offset);
    }
    [dartx.getCurrentTime]() {
      return this.getCurrentTime();
    }
    [dartx.getSimpleDuration]() {
      return this.getSimpleDuration();
    }
    [dartx.getStartTime]() {
      return this.getStartTime();
    }
    get [dartx.requiredExtensions]() {
      return this.requiredExtensions;
    }
    get [dartx.requiredFeatures]() {
      return this.requiredFeatures;
    }
    get [dartx.systemLanguage]() {
      return this.systemLanguage;
    }
    [dartx.hasExtension](extension) {
      return this.hasExtension(extension);
    }
  }
  AnimationElement[dart.implements] = () => [Tests];
  dart.defineNamedConstructor(AnimationElement, 'created');
  dart.setSignature(AnimationElement, {
    constructors: () => ({
      _: [AnimationElement, []],
      new: [AnimationElement, []],
      created: [AnimationElement, []]
    }),
    methods: () => ({
      [dartx.beginElement]: [dart.void, []],
      [dartx.beginElementAt]: [dart.void, [core.num]],
      [dartx.endElement]: [dart.void, []],
      [dartx.endElementAt]: [dart.void, [core.num]],
      [dartx.getCurrentTime]: [core.double, []],
      [dartx.getSimpleDuration]: [core.double, []],
      [dartx.getStartTime]: [core.double, []],
      [dartx.hasExtension]: [core.bool, [core.String]]
    })
  });
  AnimationElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGAnimationElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGAnimationElement"))];
  dart.registerExtension(dart.global.SVGAnimationElement, AnimationElement);
  class AnimateElement extends AnimationElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("animate"), AnimateElement);
    }
    created() {
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('animate')) && dart.is(SvgElement.tag('animate'), AnimateElement);
    }
  }
  dart.defineNamedConstructor(AnimateElement, 'created');
  dart.setSignature(AnimateElement, {
    constructors: () => ({
      _: [AnimateElement, []],
      new: [AnimateElement, []],
      created: [AnimateElement, []]
    })
  });
  AnimateElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGAnimateElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGAnimateElement"))];
  dart.registerExtension(dart.global.SVGAnimateElement, AnimateElement);
  class AnimateMotionElement extends AnimationElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("animateMotion"), AnimateMotionElement);
    }
    created() {
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('animateMotion')) && dart.is(SvgElement.tag('animateMotion'), AnimateMotionElement);
    }
  }
  dart.defineNamedConstructor(AnimateMotionElement, 'created');
  dart.setSignature(AnimateMotionElement, {
    constructors: () => ({
      _: [AnimateMotionElement, []],
      new: [AnimateMotionElement, []],
      created: [AnimateMotionElement, []]
    })
  });
  AnimateMotionElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGAnimateMotionElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGAnimateMotionElement"))];
  dart.registerExtension(dart.global.SVGAnimateMotionElement, AnimateMotionElement);
  class AnimateTransformElement extends AnimationElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("animateTransform"), AnimateTransformElement);
    }
    created() {
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('animateTransform')) && dart.is(SvgElement.tag('animateTransform'), AnimateTransformElement);
    }
  }
  dart.defineNamedConstructor(AnimateTransformElement, 'created');
  dart.setSignature(AnimateTransformElement, {
    constructors: () => ({
      _: [AnimateTransformElement, []],
      new: [AnimateTransformElement, []],
      created: [AnimateTransformElement, []]
    })
  });
  AnimateTransformElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGAnimateTransformElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGAnimateTransformElement"))];
  dart.registerExtension(dart.global.SVGAnimateTransformElement, AnimateTransformElement);
  dart.defineExtensionNames([
    'animVal',
    'baseVal'
  ]);
  class AnimatedAngle extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.animVal]() {
      return this.animVal;
    }
    get [dartx.baseVal]() {
      return this.baseVal;
    }
  }
  dart.setSignature(AnimatedAngle, {
    constructors: () => ({_: [AnimatedAngle, []]})
  });
  AnimatedAngle[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGAnimatedAngle')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGAnimatedAngle"))];
  dart.registerExtension(dart.global.SVGAnimatedAngle, AnimatedAngle);
  dart.defineExtensionNames([
    'animVal',
    'baseVal'
  ]);
  class AnimatedBoolean extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.animVal]() {
      return this.animVal;
    }
    get [dartx.baseVal]() {
      return this.baseVal;
    }
    set [dartx.baseVal](value) {
      this.baseVal = value;
    }
  }
  dart.setSignature(AnimatedBoolean, {
    constructors: () => ({_: [AnimatedBoolean, []]})
  });
  AnimatedBoolean[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGAnimatedBoolean')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGAnimatedBoolean"))];
  dart.registerExtension(dart.global.SVGAnimatedBoolean, AnimatedBoolean);
  dart.defineExtensionNames([
    'animVal',
    'baseVal'
  ]);
  class AnimatedEnumeration extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.animVal]() {
      return this.animVal;
    }
    get [dartx.baseVal]() {
      return this.baseVal;
    }
    set [dartx.baseVal](value) {
      this.baseVal = value;
    }
  }
  dart.setSignature(AnimatedEnumeration, {
    constructors: () => ({_: [AnimatedEnumeration, []]})
  });
  AnimatedEnumeration[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGAnimatedEnumeration')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGAnimatedEnumeration"))];
  dart.registerExtension(dart.global.SVGAnimatedEnumeration, AnimatedEnumeration);
  dart.defineExtensionNames([
    'animVal',
    'baseVal'
  ]);
  class AnimatedInteger extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.animVal]() {
      return this.animVal;
    }
    get [dartx.baseVal]() {
      return this.baseVal;
    }
    set [dartx.baseVal](value) {
      this.baseVal = value;
    }
  }
  dart.setSignature(AnimatedInteger, {
    constructors: () => ({_: [AnimatedInteger, []]})
  });
  AnimatedInteger[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGAnimatedInteger')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGAnimatedInteger"))];
  dart.registerExtension(dart.global.SVGAnimatedInteger, AnimatedInteger);
  dart.defineExtensionNames([
    'animVal',
    'baseVal'
  ]);
  class AnimatedLength extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.animVal]() {
      return this.animVal;
    }
    get [dartx.baseVal]() {
      return this.baseVal;
    }
  }
  dart.setSignature(AnimatedLength, {
    constructors: () => ({_: [AnimatedLength, []]})
  });
  AnimatedLength[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGAnimatedLength')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGAnimatedLength"))];
  dart.registerExtension(dart.global.SVGAnimatedLength, AnimatedLength);
  dart.defineExtensionNames([
    'animVal',
    'baseVal'
  ]);
  class AnimatedLengthList extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.animVal]() {
      return this.animVal;
    }
    get [dartx.baseVal]() {
      return this.baseVal;
    }
  }
  dart.setSignature(AnimatedLengthList, {
    constructors: () => ({_: [AnimatedLengthList, []]})
  });
  AnimatedLengthList[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGAnimatedLengthList')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGAnimatedLengthList"))];
  dart.registerExtension(dart.global.SVGAnimatedLengthList, AnimatedLengthList);
  dart.defineExtensionNames([
    'animVal',
    'baseVal'
  ]);
  class AnimatedNumber extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.animVal]() {
      return this.animVal;
    }
    get [dartx.baseVal]() {
      return this.baseVal;
    }
    set [dartx.baseVal](value) {
      this.baseVal = value;
    }
  }
  dart.setSignature(AnimatedNumber, {
    constructors: () => ({_: [AnimatedNumber, []]})
  });
  AnimatedNumber[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGAnimatedNumber')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGAnimatedNumber"))];
  dart.registerExtension(dart.global.SVGAnimatedNumber, AnimatedNumber);
  dart.defineExtensionNames([
    'animVal',
    'baseVal'
  ]);
  class AnimatedNumberList extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.animVal]() {
      return this.animVal;
    }
    get [dartx.baseVal]() {
      return this.baseVal;
    }
  }
  dart.setSignature(AnimatedNumberList, {
    constructors: () => ({_: [AnimatedNumberList, []]})
  });
  AnimatedNumberList[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGAnimatedNumberList')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGAnimatedNumberList"))];
  dart.registerExtension(dart.global.SVGAnimatedNumberList, AnimatedNumberList);
  dart.defineExtensionNames([
    'animVal',
    'baseVal'
  ]);
  class AnimatedPreserveAspectRatio extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.animVal]() {
      return this.animVal;
    }
    get [dartx.baseVal]() {
      return this.baseVal;
    }
  }
  dart.setSignature(AnimatedPreserveAspectRatio, {
    constructors: () => ({_: [AnimatedPreserveAspectRatio, []]})
  });
  AnimatedPreserveAspectRatio[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGAnimatedPreserveAspectRatio')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGAnimatedPreserveAspectRatio"))];
  dart.registerExtension(dart.global.SVGAnimatedPreserveAspectRatio, AnimatedPreserveAspectRatio);
  dart.defineExtensionNames([
    'animVal',
    'baseVal'
  ]);
  class AnimatedRect extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.animVal]() {
      return this.animVal;
    }
    get [dartx.baseVal]() {
      return this.baseVal;
    }
  }
  dart.setSignature(AnimatedRect, {
    constructors: () => ({_: [AnimatedRect, []]})
  });
  AnimatedRect[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGAnimatedRect')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGAnimatedRect"))];
  dart.registerExtension(dart.global.SVGAnimatedRect, AnimatedRect);
  dart.defineExtensionNames([
    'animVal',
    'baseVal'
  ]);
  class AnimatedString extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.animVal]() {
      return this.animVal;
    }
    get [dartx.baseVal]() {
      return this.baseVal;
    }
    set [dartx.baseVal](value) {
      this.baseVal = value;
    }
  }
  dart.setSignature(AnimatedString, {
    constructors: () => ({_: [AnimatedString, []]})
  });
  AnimatedString[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGAnimatedString')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGAnimatedString"))];
  dart.registerExtension(dart.global.SVGAnimatedString, AnimatedString);
  dart.defineExtensionNames([
    'animVal',
    'baseVal'
  ]);
  class AnimatedTransformList extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.animVal]() {
      return this.animVal;
    }
    get [dartx.baseVal]() {
      return this.baseVal;
    }
  }
  dart.setSignature(AnimatedTransformList, {
    constructors: () => ({_: [AnimatedTransformList, []]})
  });
  AnimatedTransformList[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGAnimatedTransformList')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGAnimatedTransformList"))];
  dart.registerExtension(dart.global.SVGAnimatedTransformList, AnimatedTransformList);
  dart.defineExtensionNames([
    'isPointInFill',
    'isPointInStroke'
  ]);
  class GeometryElement extends GraphicsElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      super.created();
    }
    [dartx.isPointInFill](point) {
      return this.isPointInFill(point);
    }
    [dartx.isPointInStroke](point) {
      return this.isPointInStroke(point);
    }
  }
  dart.defineNamedConstructor(GeometryElement, 'created');
  dart.setSignature(GeometryElement, {
    constructors: () => ({
      _: [GeometryElement, []],
      created: [GeometryElement, []]
    }),
    methods: () => ({
      [dartx.isPointInFill]: [core.bool, [Point]],
      [dartx.isPointInStroke]: [core.bool, [Point]]
    })
  });
  GeometryElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGGeometryElement')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("SVGGeometryElement"))];
  dart.registerExtension(dart.global.SVGGeometryElement, GeometryElement);
  dart.defineExtensionNames([
    'cx',
    'cy',
    'r'
  ]);
  class CircleElement extends GeometryElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("circle"), CircleElement);
    }
    created() {
      this[dartx.cx] = null;
      this[dartx.cy] = null;
      this[dartx.r] = null;
      super.created();
    }
    get [dartx.cx]() {
      return this.cx;
    }
    get [dartx.cy]() {
      return this.cy;
    }
    get [dartx.r]() {
      return this.r;
    }
  }
  dart.defineNamedConstructor(CircleElement, 'created');
  dart.setSignature(CircleElement, {
    constructors: () => ({
      _: [CircleElement, []],
      new: [CircleElement, []],
      created: [CircleElement, []]
    })
  });
  CircleElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGCircleElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGCircleElement"))];
  dart.registerExtension(dart.global.SVGCircleElement, CircleElement);
  dart.defineExtensionNames([
    'clipPathUnits'
  ]);
  class ClipPathElement extends GraphicsElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("clipPath"), ClipPathElement);
    }
    created() {
      this[dartx.clipPathUnits] = null;
      super.created();
    }
    get [dartx.clipPathUnits]() {
      return this.clipPathUnits;
    }
  }
  dart.defineNamedConstructor(ClipPathElement, 'created');
  dart.setSignature(ClipPathElement, {
    constructors: () => ({
      _: [ClipPathElement, []],
      new: [ClipPathElement, []],
      created: [ClipPathElement, []]
    })
  });
  ClipPathElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGClipPathElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGClipPathElement"))];
  dart.registerExtension(dart.global.SVGClipPathElement, ClipPathElement);
  class DefsElement extends GraphicsElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("defs"), DefsElement);
    }
    created() {
      super.created();
    }
  }
  dart.defineNamedConstructor(DefsElement, 'created');
  dart.setSignature(DefsElement, {
    constructors: () => ({
      _: [DefsElement, []],
      new: [DefsElement, []],
      created: [DefsElement, []]
    })
  });
  DefsElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGDefsElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGDefsElement"))];
  dart.registerExtension(dart.global.SVGDefsElement, DefsElement);
  class DescElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("desc"), DescElement);
    }
    created() {
      super.created();
    }
  }
  dart.defineNamedConstructor(DescElement, 'created');
  dart.setSignature(DescElement, {
    constructors: () => ({
      _: [DescElement, []],
      new: [DescElement, []],
      created: [DescElement, []]
    })
  });
  DescElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGDescElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGDescElement"))];
  dart.registerExtension(dart.global.SVGDescElement, DescElement);
  class DiscardElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      super.created();
    }
  }
  dart.defineNamedConstructor(DiscardElement, 'created');
  dart.setSignature(DiscardElement, {
    constructors: () => ({
      _: [DiscardElement, []],
      created: [DiscardElement, []]
    })
  });
  DiscardElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGDiscardElement')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("SVGDiscardElement"))];
  dart.registerExtension(dart.global.SVGDiscardElement, DiscardElement);
  dart.defineExtensionNames([
    'cx',
    'cy',
    'rx',
    'ry'
  ]);
  class EllipseElement extends GeometryElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("ellipse"), EllipseElement);
    }
    created() {
      this[dartx.cx] = null;
      this[dartx.cy] = null;
      this[dartx.rx] = null;
      this[dartx.ry] = null;
      super.created();
    }
    get [dartx.cx]() {
      return this.cx;
    }
    get [dartx.cy]() {
      return this.cy;
    }
    get [dartx.rx]() {
      return this.rx;
    }
    get [dartx.ry]() {
      return this.ry;
    }
  }
  dart.defineNamedConstructor(EllipseElement, 'created');
  dart.setSignature(EllipseElement, {
    constructors: () => ({
      _: [EllipseElement, []],
      new: [EllipseElement, []],
      created: [EllipseElement, []]
    })
  });
  EllipseElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGEllipseElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGEllipseElement"))];
  dart.registerExtension(dart.global.SVGEllipseElement, EllipseElement);
  dart.defineExtensionNames([
    'in1',
    'in2',
    'mode',
    'height',
    'result',
    'width',
    'x',
    'y'
  ]);
  class FEBlendElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("feBlend"), FEBlendElement);
    }
    created() {
      this[dartx.in1] = null;
      this[dartx.in2] = null;
      this[dartx.mode] = null;
      this[dartx.height] = null;
      this[dartx.result] = null;
      this[dartx.width] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('feBlend')) && dart.is(SvgElement.tag('feBlend'), FEBlendElement);
    }
    get [dartx.in1]() {
      return this.in1;
    }
    get [dartx.in2]() {
      return this.in2;
    }
    get [dartx.mode]() {
      return this.mode;
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.result]() {
      return this.result;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
  }
  FEBlendElement[dart.implements] = () => [FilterPrimitiveStandardAttributes];
  dart.defineNamedConstructor(FEBlendElement, 'created');
  dart.setSignature(FEBlendElement, {
    constructors: () => ({
      _: [FEBlendElement, []],
      new: [FEBlendElement, []],
      created: [FEBlendElement, []]
    })
  });
  FEBlendElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFEBlendElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFEBlendElement"))];
  FEBlendElement.SVG_FEBLEND_MODE_DARKEN = 4;
  FEBlendElement.SVG_FEBLEND_MODE_LIGHTEN = 5;
  FEBlendElement.SVG_FEBLEND_MODE_MULTIPLY = 2;
  FEBlendElement.SVG_FEBLEND_MODE_NORMAL = 1;
  FEBlendElement.SVG_FEBLEND_MODE_SCREEN = 3;
  FEBlendElement.SVG_FEBLEND_MODE_UNKNOWN = 0;
  dart.registerExtension(dart.global.SVGFEBlendElement, FEBlendElement);
  dart.defineExtensionNames([
    'in1',
    'type',
    'values',
    'height',
    'result',
    'width',
    'x',
    'y'
  ]);
  class FEColorMatrixElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("feColorMatrix"), FEColorMatrixElement);
    }
    created() {
      this[dartx.in1] = null;
      this[dartx.type] = null;
      this[dartx.values] = null;
      this[dartx.height] = null;
      this[dartx.result] = null;
      this[dartx.width] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('feColorMatrix')) && dart.is(SvgElement.tag('feColorMatrix'), FEColorMatrixElement);
    }
    get [dartx.in1]() {
      return this.in1;
    }
    get [dartx.type]() {
      return this.type;
    }
    get [dartx.values]() {
      return this.values;
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.result]() {
      return this.result;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
  }
  FEColorMatrixElement[dart.implements] = () => [FilterPrimitiveStandardAttributes];
  dart.defineNamedConstructor(FEColorMatrixElement, 'created');
  dart.setSignature(FEColorMatrixElement, {
    constructors: () => ({
      _: [FEColorMatrixElement, []],
      new: [FEColorMatrixElement, []],
      created: [FEColorMatrixElement, []]
    })
  });
  FEColorMatrixElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFEColorMatrixElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFEColorMatrixElement"))];
  FEColorMatrixElement.SVG_FECOLORMATRIX_TYPE_HUEROTATE = 3;
  FEColorMatrixElement.SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA = 4;
  FEColorMatrixElement.SVG_FECOLORMATRIX_TYPE_MATRIX = 1;
  FEColorMatrixElement.SVG_FECOLORMATRIX_TYPE_SATURATE = 2;
  FEColorMatrixElement.SVG_FECOLORMATRIX_TYPE_UNKNOWN = 0;
  dart.registerExtension(dart.global.SVGFEColorMatrixElement, FEColorMatrixElement);
  dart.defineExtensionNames([
    'in1',
    'height',
    'result',
    'width',
    'x',
    'y'
  ]);
  class FEComponentTransferElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("feComponentTransfer"), FEComponentTransferElement);
    }
    created() {
      this[dartx.in1] = null;
      this[dartx.height] = null;
      this[dartx.result] = null;
      this[dartx.width] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('feComponentTransfer')) && dart.is(SvgElement.tag('feComponentTransfer'), FEComponentTransferElement);
    }
    get [dartx.in1]() {
      return this.in1;
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.result]() {
      return this.result;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
  }
  FEComponentTransferElement[dart.implements] = () => [FilterPrimitiveStandardAttributes];
  dart.defineNamedConstructor(FEComponentTransferElement, 'created');
  dart.setSignature(FEComponentTransferElement, {
    constructors: () => ({
      _: [FEComponentTransferElement, []],
      new: [FEComponentTransferElement, []],
      created: [FEComponentTransferElement, []]
    })
  });
  FEComponentTransferElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFEComponentTransferElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFEComponentTransferElement"))];
  dart.registerExtension(dart.global.SVGFEComponentTransferElement, FEComponentTransferElement);
  dart.defineExtensionNames([
    'in1',
    'in2',
    'k1',
    'k2',
    'k3',
    'k4',
    'operator',
    'height',
    'result',
    'width',
    'x',
    'y'
  ]);
  class FECompositeElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      this[dartx.in1] = null;
      this[dartx.in2] = null;
      this[dartx.k1] = null;
      this[dartx.k2] = null;
      this[dartx.k3] = null;
      this[dartx.k4] = null;
      this[dartx.operator] = null;
      this[dartx.height] = null;
      this[dartx.result] = null;
      this[dartx.width] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      super.created();
    }
    get [dartx.in1]() {
      return this.in1;
    }
    get [dartx.in2]() {
      return this.in2;
    }
    get [dartx.k1]() {
      return this.k1;
    }
    get [dartx.k2]() {
      return this.k2;
    }
    get [dartx.k3]() {
      return this.k3;
    }
    get [dartx.k4]() {
      return this.k4;
    }
    get [dartx.operator]() {
      return this.operator;
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.result]() {
      return this.result;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
  }
  FECompositeElement[dart.implements] = () => [FilterPrimitiveStandardAttributes];
  dart.defineNamedConstructor(FECompositeElement, 'created');
  dart.setSignature(FECompositeElement, {
    constructors: () => ({
      _: [FECompositeElement, []],
      created: [FECompositeElement, []]
    })
  });
  FECompositeElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFECompositeElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFECompositeElement"))];
  FECompositeElement.SVG_FECOMPOSITE_OPERATOR_ARITHMETIC = 6;
  FECompositeElement.SVG_FECOMPOSITE_OPERATOR_ATOP = 4;
  FECompositeElement.SVG_FECOMPOSITE_OPERATOR_IN = 2;
  FECompositeElement.SVG_FECOMPOSITE_OPERATOR_OUT = 3;
  FECompositeElement.SVG_FECOMPOSITE_OPERATOR_OVER = 1;
  FECompositeElement.SVG_FECOMPOSITE_OPERATOR_UNKNOWN = 0;
  FECompositeElement.SVG_FECOMPOSITE_OPERATOR_XOR = 5;
  dart.registerExtension(dart.global.SVGFECompositeElement, FECompositeElement);
  dart.defineExtensionNames([
    'bias',
    'divisor',
    'edgeMode',
    'in1',
    'kernelMatrix',
    'kernelUnitLengthX',
    'kernelUnitLengthY',
    'orderX',
    'orderY',
    'preserveAlpha',
    'targetX',
    'targetY',
    'height',
    'result',
    'width',
    'x',
    'y'
  ]);
  class FEConvolveMatrixElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("feConvolveMatrix"), FEConvolveMatrixElement);
    }
    created() {
      this[dartx.bias] = null;
      this[dartx.divisor] = null;
      this[dartx.edgeMode] = null;
      this[dartx.in1] = null;
      this[dartx.kernelMatrix] = null;
      this[dartx.kernelUnitLengthX] = null;
      this[dartx.kernelUnitLengthY] = null;
      this[dartx.orderX] = null;
      this[dartx.orderY] = null;
      this[dartx.preserveAlpha] = null;
      this[dartx.targetX] = null;
      this[dartx.targetY] = null;
      this[dartx.height] = null;
      this[dartx.result] = null;
      this[dartx.width] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('feConvolveMatrix')) && dart.is(SvgElement.tag('feConvolveMatrix'), FEConvolveMatrixElement);
    }
    get [dartx.bias]() {
      return this.bias;
    }
    get [dartx.divisor]() {
      return this.divisor;
    }
    get [dartx.edgeMode]() {
      return this.edgeMode;
    }
    get [dartx.in1]() {
      return this.in1;
    }
    get [dartx.kernelMatrix]() {
      return this.kernelMatrix;
    }
    get [dartx.kernelUnitLengthX]() {
      return this.kernelUnitLengthX;
    }
    get [dartx.kernelUnitLengthY]() {
      return this.kernelUnitLengthY;
    }
    get [dartx.orderX]() {
      return this.orderX;
    }
    get [dartx.orderY]() {
      return this.orderY;
    }
    get [dartx.preserveAlpha]() {
      return this.preserveAlpha;
    }
    get [dartx.targetX]() {
      return this.targetX;
    }
    get [dartx.targetY]() {
      return this.targetY;
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.result]() {
      return this.result;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
  }
  FEConvolveMatrixElement[dart.implements] = () => [FilterPrimitiveStandardAttributes];
  dart.defineNamedConstructor(FEConvolveMatrixElement, 'created');
  dart.setSignature(FEConvolveMatrixElement, {
    constructors: () => ({
      _: [FEConvolveMatrixElement, []],
      new: [FEConvolveMatrixElement, []],
      created: [FEConvolveMatrixElement, []]
    })
  });
  FEConvolveMatrixElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFEConvolveMatrixElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFEConvolveMatrixElement"))];
  FEConvolveMatrixElement.SVG_EDGEMODE_DUPLICATE = 1;
  FEConvolveMatrixElement.SVG_EDGEMODE_NONE = 3;
  FEConvolveMatrixElement.SVG_EDGEMODE_UNKNOWN = 0;
  FEConvolveMatrixElement.SVG_EDGEMODE_WRAP = 2;
  dart.registerExtension(dart.global.SVGFEConvolveMatrixElement, FEConvolveMatrixElement);
  dart.defineExtensionNames([
    'diffuseConstant',
    'in1',
    'kernelUnitLengthX',
    'kernelUnitLengthY',
    'surfaceScale',
    'height',
    'result',
    'width',
    'x',
    'y'
  ]);
  class FEDiffuseLightingElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("feDiffuseLighting"), FEDiffuseLightingElement);
    }
    created() {
      this[dartx.diffuseConstant] = null;
      this[dartx.in1] = null;
      this[dartx.kernelUnitLengthX] = null;
      this[dartx.kernelUnitLengthY] = null;
      this[dartx.surfaceScale] = null;
      this[dartx.height] = null;
      this[dartx.result] = null;
      this[dartx.width] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('feDiffuseLighting')) && dart.is(SvgElement.tag('feDiffuseLighting'), FEDiffuseLightingElement);
    }
    get [dartx.diffuseConstant]() {
      return this.diffuseConstant;
    }
    get [dartx.in1]() {
      return this.in1;
    }
    get [dartx.kernelUnitLengthX]() {
      return this.kernelUnitLengthX;
    }
    get [dartx.kernelUnitLengthY]() {
      return this.kernelUnitLengthY;
    }
    get [dartx.surfaceScale]() {
      return this.surfaceScale;
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.result]() {
      return this.result;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
  }
  FEDiffuseLightingElement[dart.implements] = () => [FilterPrimitiveStandardAttributes];
  dart.defineNamedConstructor(FEDiffuseLightingElement, 'created');
  dart.setSignature(FEDiffuseLightingElement, {
    constructors: () => ({
      _: [FEDiffuseLightingElement, []],
      new: [FEDiffuseLightingElement, []],
      created: [FEDiffuseLightingElement, []]
    })
  });
  FEDiffuseLightingElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFEDiffuseLightingElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFEDiffuseLightingElement"))];
  dart.registerExtension(dart.global.SVGFEDiffuseLightingElement, FEDiffuseLightingElement);
  dart.defineExtensionNames([
    'in1',
    'in2',
    'scale',
    'xChannelSelector',
    'yChannelSelector',
    'height',
    'result',
    'width',
    'x',
    'y'
  ]);
  class FEDisplacementMapElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("feDisplacementMap"), FEDisplacementMapElement);
    }
    created() {
      this[dartx.in1] = null;
      this[dartx.in2] = null;
      this[dartx.scale] = null;
      this[dartx.xChannelSelector] = null;
      this[dartx.yChannelSelector] = null;
      this[dartx.height] = null;
      this[dartx.result] = null;
      this[dartx.width] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('feDisplacementMap')) && dart.is(SvgElement.tag('feDisplacementMap'), FEDisplacementMapElement);
    }
    get [dartx.in1]() {
      return this.in1;
    }
    get [dartx.in2]() {
      return this.in2;
    }
    get [dartx.scale]() {
      return this.scale;
    }
    get [dartx.xChannelSelector]() {
      return this.xChannelSelector;
    }
    get [dartx.yChannelSelector]() {
      return this.yChannelSelector;
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.result]() {
      return this.result;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
  }
  FEDisplacementMapElement[dart.implements] = () => [FilterPrimitiveStandardAttributes];
  dart.defineNamedConstructor(FEDisplacementMapElement, 'created');
  dart.setSignature(FEDisplacementMapElement, {
    constructors: () => ({
      _: [FEDisplacementMapElement, []],
      new: [FEDisplacementMapElement, []],
      created: [FEDisplacementMapElement, []]
    })
  });
  FEDisplacementMapElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFEDisplacementMapElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFEDisplacementMapElement"))];
  FEDisplacementMapElement.SVG_CHANNEL_A = 4;
  FEDisplacementMapElement.SVG_CHANNEL_B = 3;
  FEDisplacementMapElement.SVG_CHANNEL_G = 2;
  FEDisplacementMapElement.SVG_CHANNEL_R = 1;
  FEDisplacementMapElement.SVG_CHANNEL_UNKNOWN = 0;
  dart.registerExtension(dart.global.SVGFEDisplacementMapElement, FEDisplacementMapElement);
  dart.defineExtensionNames([
    'azimuth',
    'elevation'
  ]);
  class FEDistantLightElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("feDistantLight"), FEDistantLightElement);
    }
    created() {
      this[dartx.azimuth] = null;
      this[dartx.elevation] = null;
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('feDistantLight')) && dart.is(SvgElement.tag('feDistantLight'), FEDistantLightElement);
    }
    get [dartx.azimuth]() {
      return this.azimuth;
    }
    get [dartx.elevation]() {
      return this.elevation;
    }
  }
  dart.defineNamedConstructor(FEDistantLightElement, 'created');
  dart.setSignature(FEDistantLightElement, {
    constructors: () => ({
      _: [FEDistantLightElement, []],
      new: [FEDistantLightElement, []],
      created: [FEDistantLightElement, []]
    })
  });
  FEDistantLightElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFEDistantLightElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFEDistantLightElement"))];
  dart.registerExtension(dart.global.SVGFEDistantLightElement, FEDistantLightElement);
  dart.defineExtensionNames([
    'height',
    'result',
    'width',
    'x',
    'y'
  ]);
  class FEFloodElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("feFlood"), FEFloodElement);
    }
    created() {
      this[dartx.height] = null;
      this[dartx.result] = null;
      this[dartx.width] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('feFlood')) && dart.is(SvgElement.tag('feFlood'), FEFloodElement);
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.result]() {
      return this.result;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
  }
  FEFloodElement[dart.implements] = () => [FilterPrimitiveStandardAttributes];
  dart.defineNamedConstructor(FEFloodElement, 'created');
  dart.setSignature(FEFloodElement, {
    constructors: () => ({
      _: [FEFloodElement, []],
      new: [FEFloodElement, []],
      created: [FEFloodElement, []]
    })
  });
  FEFloodElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFEFloodElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFEFloodElement"))];
  dart.registerExtension(dart.global.SVGFEFloodElement, FEFloodElement);
  class _SVGComponentTransferFunctionElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      super.created();
    }
  }
  dart.defineNamedConstructor(_SVGComponentTransferFunctionElement, 'created');
  dart.setSignature(_SVGComponentTransferFunctionElement, {
    constructors: () => ({
      _: [_SVGComponentTransferFunctionElement, []],
      created: [_SVGComponentTransferFunctionElement, []]
    })
  });
  _SVGComponentTransferFunctionElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGComponentTransferFunctionElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGComponentTransferFunctionElement"))];
  dart.registerExtension(dart.global.SVGComponentTransferFunctionElement, _SVGComponentTransferFunctionElement);
  class FEFuncAElement extends _SVGComponentTransferFunctionElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("feFuncA"), FEFuncAElement);
    }
    created() {
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('feFuncA')) && dart.is(SvgElement.tag('feFuncA'), FEFuncAElement);
    }
  }
  dart.defineNamedConstructor(FEFuncAElement, 'created');
  dart.setSignature(FEFuncAElement, {
    constructors: () => ({
      _: [FEFuncAElement, []],
      new: [FEFuncAElement, []],
      created: [FEFuncAElement, []]
    })
  });
  FEFuncAElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFEFuncAElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFEFuncAElement"))];
  dart.registerExtension(dart.global.SVGFEFuncAElement, FEFuncAElement);
  class FEFuncBElement extends _SVGComponentTransferFunctionElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("feFuncB"), FEFuncBElement);
    }
    created() {
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('feFuncB')) && dart.is(SvgElement.tag('feFuncB'), FEFuncBElement);
    }
  }
  dart.defineNamedConstructor(FEFuncBElement, 'created');
  dart.setSignature(FEFuncBElement, {
    constructors: () => ({
      _: [FEFuncBElement, []],
      new: [FEFuncBElement, []],
      created: [FEFuncBElement, []]
    })
  });
  FEFuncBElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFEFuncBElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFEFuncBElement"))];
  dart.registerExtension(dart.global.SVGFEFuncBElement, FEFuncBElement);
  class FEFuncGElement extends _SVGComponentTransferFunctionElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("feFuncG"), FEFuncGElement);
    }
    created() {
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('feFuncG')) && dart.is(SvgElement.tag('feFuncG'), FEFuncGElement);
    }
  }
  dart.defineNamedConstructor(FEFuncGElement, 'created');
  dart.setSignature(FEFuncGElement, {
    constructors: () => ({
      _: [FEFuncGElement, []],
      new: [FEFuncGElement, []],
      created: [FEFuncGElement, []]
    })
  });
  FEFuncGElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFEFuncGElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFEFuncGElement"))];
  dart.registerExtension(dart.global.SVGFEFuncGElement, FEFuncGElement);
  class FEFuncRElement extends _SVGComponentTransferFunctionElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("feFuncR"), FEFuncRElement);
    }
    created() {
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('feFuncR')) && dart.is(SvgElement.tag('feFuncR'), FEFuncRElement);
    }
  }
  dart.defineNamedConstructor(FEFuncRElement, 'created');
  dart.setSignature(FEFuncRElement, {
    constructors: () => ({
      _: [FEFuncRElement, []],
      new: [FEFuncRElement, []],
      created: [FEFuncRElement, []]
    })
  });
  FEFuncRElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFEFuncRElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFEFuncRElement"))];
  dart.registerExtension(dart.global.SVGFEFuncRElement, FEFuncRElement);
  dart.defineExtensionNames([
    'setStdDeviation',
    'in1',
    'stdDeviationX',
    'stdDeviationY',
    'height',
    'result',
    'width',
    'x',
    'y'
  ]);
  class FEGaussianBlurElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("feGaussianBlur"), FEGaussianBlurElement);
    }
    created() {
      this[dartx.in1] = null;
      this[dartx.stdDeviationX] = null;
      this[dartx.stdDeviationY] = null;
      this[dartx.height] = null;
      this[dartx.result] = null;
      this[dartx.width] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('feGaussianBlur')) && dart.is(SvgElement.tag('feGaussianBlur'), FEGaussianBlurElement);
    }
    get [dartx.in1]() {
      return this.in1;
    }
    get [dartx.stdDeviationX]() {
      return this.stdDeviationX;
    }
    get [dartx.stdDeviationY]() {
      return this.stdDeviationY;
    }
    [dartx.setStdDeviation](stdDeviationX, stdDeviationY) {
      return this.setStdDeviation(stdDeviationX, stdDeviationY);
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.result]() {
      return this.result;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
  }
  FEGaussianBlurElement[dart.implements] = () => [FilterPrimitiveStandardAttributes];
  dart.defineNamedConstructor(FEGaussianBlurElement, 'created');
  dart.setSignature(FEGaussianBlurElement, {
    constructors: () => ({
      _: [FEGaussianBlurElement, []],
      new: [FEGaussianBlurElement, []],
      created: [FEGaussianBlurElement, []]
    }),
    methods: () => ({[dartx.setStdDeviation]: [dart.void, [core.num, core.num]]})
  });
  FEGaussianBlurElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFEGaussianBlurElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFEGaussianBlurElement"))];
  dart.registerExtension(dart.global.SVGFEGaussianBlurElement, FEGaussianBlurElement);
  dart.defineExtensionNames([
    'preserveAspectRatio',
    'height',
    'result',
    'width',
    'x',
    'y',
    'href'
  ]);
  class FEImageElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("feImage"), FEImageElement);
    }
    created() {
      this[dartx.preserveAspectRatio] = null;
      this[dartx.height] = null;
      this[dartx.result] = null;
      this[dartx.width] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      this[dartx.href] = null;
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('feImage')) && dart.is(SvgElement.tag('feImage'), FEImageElement);
    }
    get [dartx.preserveAspectRatio]() {
      return this.preserveAspectRatio;
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.result]() {
      return this.result;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
    get [dartx.href]() {
      return this.href;
    }
  }
  FEImageElement[dart.implements] = () => [FilterPrimitiveStandardAttributes, UriReference];
  dart.defineNamedConstructor(FEImageElement, 'created');
  dart.setSignature(FEImageElement, {
    constructors: () => ({
      _: [FEImageElement, []],
      new: [FEImageElement, []],
      created: [FEImageElement, []]
    })
  });
  FEImageElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFEImageElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFEImageElement"))];
  dart.registerExtension(dart.global.SVGFEImageElement, FEImageElement);
  dart.defineExtensionNames([
    'height',
    'result',
    'width',
    'x',
    'y'
  ]);
  class FEMergeElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("feMerge"), FEMergeElement);
    }
    created() {
      this[dartx.height] = null;
      this[dartx.result] = null;
      this[dartx.width] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('feMerge')) && dart.is(SvgElement.tag('feMerge'), FEMergeElement);
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.result]() {
      return this.result;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
  }
  FEMergeElement[dart.implements] = () => [FilterPrimitiveStandardAttributes];
  dart.defineNamedConstructor(FEMergeElement, 'created');
  dart.setSignature(FEMergeElement, {
    constructors: () => ({
      _: [FEMergeElement, []],
      new: [FEMergeElement, []],
      created: [FEMergeElement, []]
    })
  });
  FEMergeElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFEMergeElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFEMergeElement"))];
  dart.registerExtension(dart.global.SVGFEMergeElement, FEMergeElement);
  dart.defineExtensionNames([
    'in1'
  ]);
  class FEMergeNodeElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("feMergeNode"), FEMergeNodeElement);
    }
    created() {
      this[dartx.in1] = null;
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('feMergeNode')) && dart.is(SvgElement.tag('feMergeNode'), FEMergeNodeElement);
    }
    get [dartx.in1]() {
      return this.in1;
    }
  }
  dart.defineNamedConstructor(FEMergeNodeElement, 'created');
  dart.setSignature(FEMergeNodeElement, {
    constructors: () => ({
      _: [FEMergeNodeElement, []],
      new: [FEMergeNodeElement, []],
      created: [FEMergeNodeElement, []]
    })
  });
  FEMergeNodeElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFEMergeNodeElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFEMergeNodeElement"))];
  dart.registerExtension(dart.global.SVGFEMergeNodeElement, FEMergeNodeElement);
  dart.defineExtensionNames([
    'in1',
    'operator',
    'radiusX',
    'radiusY',
    'height',
    'result',
    'width',
    'x',
    'y'
  ]);
  class FEMorphologyElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      this[dartx.in1] = null;
      this[dartx.operator] = null;
      this[dartx.radiusX] = null;
      this[dartx.radiusY] = null;
      this[dartx.height] = null;
      this[dartx.result] = null;
      this[dartx.width] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      super.created();
    }
    get [dartx.in1]() {
      return this.in1;
    }
    get [dartx.operator]() {
      return this.operator;
    }
    get [dartx.radiusX]() {
      return this.radiusX;
    }
    get [dartx.radiusY]() {
      return this.radiusY;
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.result]() {
      return this.result;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
  }
  FEMorphologyElement[dart.implements] = () => [FilterPrimitiveStandardAttributes];
  dart.defineNamedConstructor(FEMorphologyElement, 'created');
  dart.setSignature(FEMorphologyElement, {
    constructors: () => ({
      _: [FEMorphologyElement, []],
      created: [FEMorphologyElement, []]
    })
  });
  FEMorphologyElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFEMorphologyElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFEMorphologyElement"))];
  FEMorphologyElement.SVG_MORPHOLOGY_OPERATOR_DILATE = 2;
  FEMorphologyElement.SVG_MORPHOLOGY_OPERATOR_ERODE = 1;
  FEMorphologyElement.SVG_MORPHOLOGY_OPERATOR_UNKNOWN = 0;
  dart.registerExtension(dart.global.SVGFEMorphologyElement, FEMorphologyElement);
  dart.defineExtensionNames([
    'dx',
    'dy',
    'in1',
    'height',
    'result',
    'width',
    'x',
    'y'
  ]);
  class FEOffsetElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("feOffset"), FEOffsetElement);
    }
    created() {
      this[dartx.dx] = null;
      this[dartx.dy] = null;
      this[dartx.in1] = null;
      this[dartx.height] = null;
      this[dartx.result] = null;
      this[dartx.width] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('feOffset')) && dart.is(SvgElement.tag('feOffset'), FEOffsetElement);
    }
    get [dartx.dx]() {
      return this.dx;
    }
    get [dartx.dy]() {
      return this.dy;
    }
    get [dartx.in1]() {
      return this.in1;
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.result]() {
      return this.result;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
  }
  FEOffsetElement[dart.implements] = () => [FilterPrimitiveStandardAttributes];
  dart.defineNamedConstructor(FEOffsetElement, 'created');
  dart.setSignature(FEOffsetElement, {
    constructors: () => ({
      _: [FEOffsetElement, []],
      new: [FEOffsetElement, []],
      created: [FEOffsetElement, []]
    })
  });
  FEOffsetElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFEOffsetElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFEOffsetElement"))];
  dart.registerExtension(dart.global.SVGFEOffsetElement, FEOffsetElement);
  dart.defineExtensionNames([
    'x',
    'y',
    'z'
  ]);
  class FEPointLightElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("fePointLight"), FEPointLightElement);
    }
    created() {
      this[dartx.x] = null;
      this[dartx.y] = null;
      this[dartx.z] = null;
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('fePointLight')) && dart.is(SvgElement.tag('fePointLight'), FEPointLightElement);
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
    get [dartx.z]() {
      return this.z;
    }
  }
  dart.defineNamedConstructor(FEPointLightElement, 'created');
  dart.setSignature(FEPointLightElement, {
    constructors: () => ({
      _: [FEPointLightElement, []],
      new: [FEPointLightElement, []],
      created: [FEPointLightElement, []]
    })
  });
  FEPointLightElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFEPointLightElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFEPointLightElement"))];
  dart.registerExtension(dart.global.SVGFEPointLightElement, FEPointLightElement);
  dart.defineExtensionNames([
    'in1',
    'specularConstant',
    'specularExponent',
    'surfaceScale',
    'height',
    'result',
    'width',
    'x',
    'y'
  ]);
  class FESpecularLightingElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("feSpecularLighting"), FESpecularLightingElement);
    }
    created() {
      this[dartx.in1] = null;
      this[dartx.specularConstant] = null;
      this[dartx.specularExponent] = null;
      this[dartx.surfaceScale] = null;
      this[dartx.height] = null;
      this[dartx.result] = null;
      this[dartx.width] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('feSpecularLighting')) && dart.is(SvgElement.tag('feSpecularLighting'), FESpecularLightingElement);
    }
    get [dartx.in1]() {
      return this.in1;
    }
    get [dartx.specularConstant]() {
      return this.specularConstant;
    }
    get [dartx.specularExponent]() {
      return this.specularExponent;
    }
    get [dartx.surfaceScale]() {
      return this.surfaceScale;
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.result]() {
      return this.result;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
  }
  FESpecularLightingElement[dart.implements] = () => [FilterPrimitiveStandardAttributes];
  dart.defineNamedConstructor(FESpecularLightingElement, 'created');
  dart.setSignature(FESpecularLightingElement, {
    constructors: () => ({
      _: [FESpecularLightingElement, []],
      new: [FESpecularLightingElement, []],
      created: [FESpecularLightingElement, []]
    })
  });
  FESpecularLightingElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFESpecularLightingElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFESpecularLightingElement"))];
  dart.registerExtension(dart.global.SVGFESpecularLightingElement, FESpecularLightingElement);
  dart.defineExtensionNames([
    'limitingConeAngle',
    'pointsAtX',
    'pointsAtY',
    'pointsAtZ',
    'specularExponent',
    'x',
    'y',
    'z'
  ]);
  class FESpotLightElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("feSpotLight"), FESpotLightElement);
    }
    created() {
      this[dartx.limitingConeAngle] = null;
      this[dartx.pointsAtX] = null;
      this[dartx.pointsAtY] = null;
      this[dartx.pointsAtZ] = null;
      this[dartx.specularExponent] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      this[dartx.z] = null;
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('feSpotLight')) && dart.is(SvgElement.tag('feSpotLight'), FESpotLightElement);
    }
    get [dartx.limitingConeAngle]() {
      return this.limitingConeAngle;
    }
    get [dartx.pointsAtX]() {
      return this.pointsAtX;
    }
    get [dartx.pointsAtY]() {
      return this.pointsAtY;
    }
    get [dartx.pointsAtZ]() {
      return this.pointsAtZ;
    }
    get [dartx.specularExponent]() {
      return this.specularExponent;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
    get [dartx.z]() {
      return this.z;
    }
  }
  dart.defineNamedConstructor(FESpotLightElement, 'created');
  dart.setSignature(FESpotLightElement, {
    constructors: () => ({
      _: [FESpotLightElement, []],
      new: [FESpotLightElement, []],
      created: [FESpotLightElement, []]
    })
  });
  FESpotLightElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFESpotLightElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFESpotLightElement"))];
  dart.registerExtension(dart.global.SVGFESpotLightElement, FESpotLightElement);
  dart.defineExtensionNames([
    'in1',
    'height',
    'result',
    'width',
    'x',
    'y'
  ]);
  class FETileElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("feTile"), FETileElement);
    }
    created() {
      this[dartx.in1] = null;
      this[dartx.height] = null;
      this[dartx.result] = null;
      this[dartx.width] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('feTile')) && dart.is(SvgElement.tag('feTile'), FETileElement);
    }
    get [dartx.in1]() {
      return this.in1;
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.result]() {
      return this.result;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
  }
  FETileElement[dart.implements] = () => [FilterPrimitiveStandardAttributes];
  dart.defineNamedConstructor(FETileElement, 'created');
  dart.setSignature(FETileElement, {
    constructors: () => ({
      _: [FETileElement, []],
      new: [FETileElement, []],
      created: [FETileElement, []]
    })
  });
  FETileElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFETileElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFETileElement"))];
  dart.registerExtension(dart.global.SVGFETileElement, FETileElement);
  dart.defineExtensionNames([
    'baseFrequencyX',
    'baseFrequencyY',
    'numOctaves',
    'seed',
    'stitchTiles',
    'type',
    'height',
    'result',
    'width',
    'x',
    'y'
  ]);
  class FETurbulenceElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("feTurbulence"), FETurbulenceElement);
    }
    created() {
      this[dartx.baseFrequencyX] = null;
      this[dartx.baseFrequencyY] = null;
      this[dartx.numOctaves] = null;
      this[dartx.seed] = null;
      this[dartx.stitchTiles] = null;
      this[dartx.type] = null;
      this[dartx.height] = null;
      this[dartx.result] = null;
      this[dartx.width] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('feTurbulence')) && dart.is(SvgElement.tag('feTurbulence'), FETurbulenceElement);
    }
    get [dartx.baseFrequencyX]() {
      return this.baseFrequencyX;
    }
    get [dartx.baseFrequencyY]() {
      return this.baseFrequencyY;
    }
    get [dartx.numOctaves]() {
      return this.numOctaves;
    }
    get [dartx.seed]() {
      return this.seed;
    }
    get [dartx.stitchTiles]() {
      return this.stitchTiles;
    }
    get [dartx.type]() {
      return this.type;
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.result]() {
      return this.result;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
  }
  FETurbulenceElement[dart.implements] = () => [FilterPrimitiveStandardAttributes];
  dart.defineNamedConstructor(FETurbulenceElement, 'created');
  dart.setSignature(FETurbulenceElement, {
    constructors: () => ({
      _: [FETurbulenceElement, []],
      new: [FETurbulenceElement, []],
      created: [FETurbulenceElement, []]
    })
  });
  FETurbulenceElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFETurbulenceElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFETurbulenceElement"))];
  FETurbulenceElement.SVG_STITCHTYPE_NOSTITCH = 2;
  FETurbulenceElement.SVG_STITCHTYPE_STITCH = 1;
  FETurbulenceElement.SVG_STITCHTYPE_UNKNOWN = 0;
  FETurbulenceElement.SVG_TURBULENCE_TYPE_FRACTALNOISE = 1;
  FETurbulenceElement.SVG_TURBULENCE_TYPE_TURBULENCE = 2;
  FETurbulenceElement.SVG_TURBULENCE_TYPE_UNKNOWN = 0;
  dart.registerExtension(dart.global.SVGFETurbulenceElement, FETurbulenceElement);
  dart.defineExtensionNames([
    'setFilterRes',
    'filterResX',
    'filterResY',
    'filterUnits',
    'height',
    'primitiveUnits',
    'width',
    'x',
    'y',
    'href'
  ]);
  class FilterElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("filter"), FilterElement);
    }
    created() {
      this[dartx.filterResX] = null;
      this[dartx.filterResY] = null;
      this[dartx.filterUnits] = null;
      this[dartx.height] = null;
      this[dartx.primitiveUnits] = null;
      this[dartx.width] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      this[dartx.href] = null;
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('filter')) && dart.is(SvgElement.tag('filter'), FilterElement);
    }
    get [dartx.filterResX]() {
      return this.filterResX;
    }
    get [dartx.filterResY]() {
      return this.filterResY;
    }
    get [dartx.filterUnits]() {
      return this.filterUnits;
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.primitiveUnits]() {
      return this.primitiveUnits;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
    [dartx.setFilterRes](filterResX, filterResY) {
      return this.setFilterRes(filterResX, filterResY);
    }
    get [dartx.href]() {
      return this.href;
    }
  }
  FilterElement[dart.implements] = () => [UriReference];
  dart.defineNamedConstructor(FilterElement, 'created');
  dart.setSignature(FilterElement, {
    constructors: () => ({
      _: [FilterElement, []],
      new: [FilterElement, []],
      created: [FilterElement, []]
    }),
    methods: () => ({[dartx.setFilterRes]: [dart.void, [core.int, core.int]]})
  });
  FilterElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFilterElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFilterElement"))];
  dart.registerExtension(dart.global.SVGFilterElement, FilterElement);
  dart.defineExtensionNames([
    'height',
    'result',
    'width',
    'x',
    'y'
  ]);
  class FilterPrimitiveStandardAttributes extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.result]() {
      return this.result;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
  }
  dart.setSignature(FilterPrimitiveStandardAttributes, {
    constructors: () => ({_: [FilterPrimitiveStandardAttributes, []]})
  });
  FilterPrimitiveStandardAttributes[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFilterPrimitiveStandardAttributes')), dart.const(new _metadata.Unstable())];
  dart.defineExtensionNames([
    'preserveAspectRatio',
    'viewBox'
  ]);
  class FitToViewBox extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.preserveAspectRatio]() {
      return this.preserveAspectRatio;
    }
    get [dartx.viewBox]() {
      return this.viewBox;
    }
  }
  dart.setSignature(FitToViewBox, {
    constructors: () => ({_: [FitToViewBox, []]})
  });
  FitToViewBox[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFitToViewBox')), dart.const(new _metadata.Unstable())];
  dart.defineExtensionNames([
    'height',
    'width',
    'x',
    'y'
  ]);
  class ForeignObjectElement extends GraphicsElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("foreignObject"), ForeignObjectElement);
    }
    created() {
      this[dartx.height] = null;
      this[dartx.width] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('foreignObject')) && dart.is(SvgElement.tag('foreignObject'), ForeignObjectElement);
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
  }
  dart.defineNamedConstructor(ForeignObjectElement, 'created');
  dart.setSignature(ForeignObjectElement, {
    constructors: () => ({
      _: [ForeignObjectElement, []],
      new: [ForeignObjectElement, []],
      created: [ForeignObjectElement, []]
    })
  });
  ForeignObjectElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGForeignObjectElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGForeignObjectElement"))];
  dart.registerExtension(dart.global.SVGForeignObjectElement, ForeignObjectElement);
  class GElement extends GraphicsElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("g"), GElement);
    }
    created() {
      super.created();
    }
  }
  dart.defineNamedConstructor(GElement, 'created');
  dart.setSignature(GElement, {
    constructors: () => ({
      _: [GElement, []],
      new: [GElement, []],
      created: [GElement, []]
    })
  });
  GElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGGElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGGElement"))];
  dart.registerExtension(dart.global.SVGGElement, GElement);
  dart.defineExtensionNames([
    'height',
    'preserveAspectRatio',
    'width',
    'x',
    'y',
    'href'
  ]);
  class ImageElement extends GraphicsElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("image"), ImageElement);
    }
    created() {
      this[dartx.height] = null;
      this[dartx.preserveAspectRatio] = null;
      this[dartx.width] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      this[dartx.href] = null;
      super.created();
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.preserveAspectRatio]() {
      return this.preserveAspectRatio;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
    get [dartx.href]() {
      return this.href;
    }
  }
  ImageElement[dart.implements] = () => [UriReference];
  dart.defineNamedConstructor(ImageElement, 'created');
  dart.setSignature(ImageElement, {
    constructors: () => ({
      _: [ImageElement, []],
      new: [ImageElement, []],
      created: [ImageElement, []]
    })
  });
  ImageElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGImageElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGImageElement"))];
  dart.registerExtension(dart.global.SVGImageElement, ImageElement);
  dart.defineExtensionNames([
    'convertToSpecifiedUnits',
    'newValueSpecifiedUnits',
    'unitType',
    'value',
    'valueAsString',
    'valueInSpecifiedUnits'
  ]);
  class Length extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.unitType]() {
      return this.unitType;
    }
    get [dartx.value]() {
      return this.value;
    }
    set [dartx.value](value) {
      this.value = value;
    }
    get [dartx.valueAsString]() {
      return this.valueAsString;
    }
    set [dartx.valueAsString](value) {
      this.valueAsString = value;
    }
    get [dartx.valueInSpecifiedUnits]() {
      return this.valueInSpecifiedUnits;
    }
    set [dartx.valueInSpecifiedUnits](value) {
      this.valueInSpecifiedUnits = value;
    }
    [dartx.convertToSpecifiedUnits](unitType) {
      return this.convertToSpecifiedUnits(unitType);
    }
    [dartx.newValueSpecifiedUnits](unitType, valueInSpecifiedUnits) {
      return this.newValueSpecifiedUnits(unitType, valueInSpecifiedUnits);
    }
  }
  dart.setSignature(Length, {
    constructors: () => ({_: [Length, []]}),
    methods: () => ({
      [dartx.convertToSpecifiedUnits]: [dart.void, [core.int]],
      [dartx.newValueSpecifiedUnits]: [dart.void, [core.int, core.num]]
    })
  });
  Length[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGLength')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGLength"))];
  Length.SVG_LENGTHTYPE_CM = 6;
  Length.SVG_LENGTHTYPE_EMS = 3;
  Length.SVG_LENGTHTYPE_EXS = 4;
  Length.SVG_LENGTHTYPE_IN = 8;
  Length.SVG_LENGTHTYPE_MM = 7;
  Length.SVG_LENGTHTYPE_NUMBER = 1;
  Length.SVG_LENGTHTYPE_PC = 10;
  Length.SVG_LENGTHTYPE_PERCENTAGE = 2;
  Length.SVG_LENGTHTYPE_PT = 9;
  Length.SVG_LENGTHTYPE_PX = 5;
  Length.SVG_LENGTHTYPE_UNKNOWN = 0;
  dart.registerExtension(dart.global.SVGLength, Length);
  const __setter__ = Symbol('__setter__');
  dart.defineExtensionNames([
    'length',
    'get',
    'set',
    'length',
    'first',
    'last',
    'single',
    'elementAt',
    'appendItem',
    'clear',
    'getItem',
    'initialize',
    'insertItemBefore',
    'removeItem',
    'replaceItem',
    'numberOfItems'
  ]);
  class LengthList extends dart.mixin(_interceptors.Interceptor, collection.ListMixin$(Length), html$.ImmutableListMixin$(Length)) {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.length]() {
      return this.length;
    }
    get [dartx.numberOfItems]() {
      return this.numberOfItems;
    }
    [dartx.get](index) {
      if (index >>> 0 !== index || index >= this[dartx.length]) dart.throw(core.RangeError.index(index, this));
      return this[dartx.getItem](index);
    }
    [dartx.set](index, value) {
      dart.throw(new core.UnsupportedError("Cannot assign element of immutable List."));
      return value;
    }
    set [dartx.length](value) {
      dart.throw(new core.UnsupportedError("Cannot resize immutable List."));
    }
    get [dartx.first]() {
      if (dart.notNull(this[dartx.length]) > 0) {
        return dart.as(this[0], Length);
      }
      dart.throw(new core.StateError("No elements"));
    }
    get [dartx.last]() {
      let len = this[dartx.length];
      if (dart.notNull(len) > 0) {
        return dart.as(this[dart.notNull(len) - 1], Length);
      }
      dart.throw(new core.StateError("No elements"));
    }
    get [dartx.single]() {
      let len = this[dartx.length];
      if (len == 1) {
        return dart.as(this[0], Length);
      }
      if (len == 0) dart.throw(new core.StateError("No elements"));
      dart.throw(new core.StateError("More than one element"));
    }
    [dartx.elementAt](index) {
      return this[dartx.get](index);
    }
    [__setter__](index, value) {
      return this.__setter__(index, value);
    }
    [dartx.appendItem](item) {
      return this.appendItem(item);
    }
    [dartx.clear]() {
      return this.clear();
    }
    [dartx.getItem](index) {
      return this.getItem(index);
    }
    [dartx.initialize](item) {
      return this.initialize(item);
    }
    [dartx.insertItemBefore](item, index) {
      return this.insertItemBefore(item, index);
    }
    [dartx.removeItem](index) {
      return this.removeItem(index);
    }
    [dartx.replaceItem](item, index) {
      return this.replaceItem(item, index);
    }
  }
  LengthList[dart.implements] = () => [core.List$(Length)];
  dart.setSignature(LengthList, {
    constructors: () => ({_: [LengthList, []]}),
    methods: () => ({
      [dartx.get]: [Length, [core.int]],
      [dartx.set]: [dart.void, [core.int, Length]],
      [dartx.elementAt]: [Length, [core.int]],
      [__setter__]: [dart.void, [core.int, Length]],
      [dartx.appendItem]: [Length, [Length]],
      [dartx.getItem]: [Length, [core.int]],
      [dartx.initialize]: [Length, [Length]],
      [dartx.insertItemBefore]: [Length, [Length, core.int]],
      [dartx.removeItem]: [Length, [core.int]],
      [dartx.replaceItem]: [Length, [Length, core.int]]
    })
  });
  LengthList[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGLengthList')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGLengthList"))];
  dart.registerExtension(dart.global.SVGLengthList, LengthList);
  dart.defineExtensionNames([
    'x1',
    'x2',
    'y1',
    'y2'
  ]);
  class LineElement extends GeometryElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("line"), LineElement);
    }
    created() {
      this[dartx.x1] = null;
      this[dartx.x2] = null;
      this[dartx.y1] = null;
      this[dartx.y2] = null;
      super.created();
    }
    get [dartx.x1]() {
      return this.x1;
    }
    get [dartx.x2]() {
      return this.x2;
    }
    get [dartx.y1]() {
      return this.y1;
    }
    get [dartx.y2]() {
      return this.y2;
    }
  }
  dart.defineNamedConstructor(LineElement, 'created');
  dart.setSignature(LineElement, {
    constructors: () => ({
      _: [LineElement, []],
      new: [LineElement, []],
      created: [LineElement, []]
    })
  });
  LineElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGLineElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGLineElement"))];
  dart.registerExtension(dart.global.SVGLineElement, LineElement);
  dart.defineExtensionNames([
    'gradientTransform',
    'gradientUnits',
    'spreadMethod',
    'href'
  ]);
  class _GradientElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      this[dartx.gradientTransform] = null;
      this[dartx.gradientUnits] = null;
      this[dartx.spreadMethod] = null;
      this[dartx.href] = null;
      super.created();
    }
    get [dartx.gradientTransform]() {
      return this.gradientTransform;
    }
    get [dartx.gradientUnits]() {
      return this.gradientUnits;
    }
    get [dartx.spreadMethod]() {
      return this.spreadMethod;
    }
    get [dartx.href]() {
      return this.href;
    }
  }
  _GradientElement[dart.implements] = () => [UriReference];
  dart.defineNamedConstructor(_GradientElement, 'created');
  dart.setSignature(_GradientElement, {
    constructors: () => ({
      _: [_GradientElement, []],
      created: [_GradientElement, []]
    })
  });
  _GradientElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGGradientElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGGradientElement"))];
  _GradientElement.SVG_SPREADMETHOD_PAD = 1;
  _GradientElement.SVG_SPREADMETHOD_REFLECT = 2;
  _GradientElement.SVG_SPREADMETHOD_REPEAT = 3;
  _GradientElement.SVG_SPREADMETHOD_UNKNOWN = 0;
  dart.registerExtension(dart.global.SVGGradientElement, _GradientElement);
  dart.defineExtensionNames([
    'x1',
    'x2',
    'y1',
    'y2'
  ]);
  class LinearGradientElement extends _GradientElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("linearGradient"), LinearGradientElement);
    }
    created() {
      this[dartx.x1] = null;
      this[dartx.x2] = null;
      this[dartx.y1] = null;
      this[dartx.y2] = null;
      super.created();
    }
    get [dartx.x1]() {
      return this.x1;
    }
    get [dartx.x2]() {
      return this.x2;
    }
    get [dartx.y1]() {
      return this.y1;
    }
    get [dartx.y2]() {
      return this.y2;
    }
  }
  dart.defineNamedConstructor(LinearGradientElement, 'created');
  dart.setSignature(LinearGradientElement, {
    constructors: () => ({
      _: [LinearGradientElement, []],
      new: [LinearGradientElement, []],
      created: [LinearGradientElement, []]
    })
  });
  LinearGradientElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGLinearGradientElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGLinearGradientElement"))];
  dart.registerExtension(dart.global.SVGLinearGradientElement, LinearGradientElement);
  dart.defineExtensionNames([
    'setOrientToAngle',
    'setOrientToAuto',
    'markerHeight',
    'markerUnits',
    'markerWidth',
    'orientAngle',
    'orientType',
    'refX',
    'refY',
    'preserveAspectRatio',
    'viewBox'
  ]);
  class MarkerElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("marker"), MarkerElement);
    }
    created() {
      this[dartx.markerHeight] = null;
      this[dartx.markerUnits] = null;
      this[dartx.markerWidth] = null;
      this[dartx.orientAngle] = null;
      this[dartx.orientType] = null;
      this[dartx.refX] = null;
      this[dartx.refY] = null;
      this[dartx.preserveAspectRatio] = null;
      this[dartx.viewBox] = null;
      super.created();
    }
    get [dartx.markerHeight]() {
      return this.markerHeight;
    }
    get [dartx.markerUnits]() {
      return this.markerUnits;
    }
    get [dartx.markerWidth]() {
      return this.markerWidth;
    }
    get [dartx.orientAngle]() {
      return this.orientAngle;
    }
    get [dartx.orientType]() {
      return this.orientType;
    }
    get [dartx.refX]() {
      return this.refX;
    }
    get [dartx.refY]() {
      return this.refY;
    }
    [dartx.setOrientToAngle](angle) {
      return this.setOrientToAngle(angle);
    }
    [dartx.setOrientToAuto]() {
      return this.setOrientToAuto();
    }
    get [dartx.preserveAspectRatio]() {
      return this.preserveAspectRatio;
    }
    get [dartx.viewBox]() {
      return this.viewBox;
    }
  }
  MarkerElement[dart.implements] = () => [FitToViewBox];
  dart.defineNamedConstructor(MarkerElement, 'created');
  dart.setSignature(MarkerElement, {
    constructors: () => ({
      _: [MarkerElement, []],
      new: [MarkerElement, []],
      created: [MarkerElement, []]
    }),
    methods: () => ({
      [dartx.setOrientToAngle]: [dart.void, [Angle]],
      [dartx.setOrientToAuto]: [dart.void, []]
    })
  });
  MarkerElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGMarkerElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGMarkerElement"))];
  MarkerElement.SVG_MARKERUNITS_STROKEWIDTH = 2;
  MarkerElement.SVG_MARKERUNITS_UNKNOWN = 0;
  MarkerElement.SVG_MARKERUNITS_USERSPACEONUSE = 1;
  MarkerElement.SVG_MARKER_ORIENT_ANGLE = 2;
  MarkerElement.SVG_MARKER_ORIENT_AUTO = 1;
  MarkerElement.SVG_MARKER_ORIENT_UNKNOWN = 0;
  dart.registerExtension(dart.global.SVGMarkerElement, MarkerElement);
  dart.defineExtensionNames([
    'hasExtension',
    'height',
    'maskContentUnits',
    'maskUnits',
    'width',
    'x',
    'y',
    'requiredExtensions',
    'requiredFeatures',
    'systemLanguage'
  ]);
  class MaskElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("mask"), MaskElement);
    }
    created() {
      this[dartx.height] = null;
      this[dartx.maskContentUnits] = null;
      this[dartx.maskUnits] = null;
      this[dartx.width] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      this[dartx.requiredExtensions] = null;
      this[dartx.requiredFeatures] = null;
      this[dartx.systemLanguage] = null;
      super.created();
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.maskContentUnits]() {
      return this.maskContentUnits;
    }
    get [dartx.maskUnits]() {
      return this.maskUnits;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
    get [dartx.requiredExtensions]() {
      return this.requiredExtensions;
    }
    get [dartx.requiredFeatures]() {
      return this.requiredFeatures;
    }
    get [dartx.systemLanguage]() {
      return this.systemLanguage;
    }
    [dartx.hasExtension](extension) {
      return this.hasExtension(extension);
    }
  }
  MaskElement[dart.implements] = () => [Tests];
  dart.defineNamedConstructor(MaskElement, 'created');
  dart.setSignature(MaskElement, {
    constructors: () => ({
      _: [MaskElement, []],
      new: [MaskElement, []],
      created: [MaskElement, []]
    }),
    methods: () => ({[dartx.hasExtension]: [core.bool, [core.String]]})
  });
  MaskElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGMaskElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGMaskElement"))];
  dart.registerExtension(dart.global.SVGMaskElement, MaskElement);
  dart.defineExtensionNames([
    'flipX',
    'flipY',
    'inverse',
    'multiply',
    'rotate',
    'rotateFromVector',
    'scale',
    'scaleNonUniform',
    'skewX',
    'skewY',
    'translate',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f'
  ]);
  class Matrix extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.a]() {
      return this.a;
    }
    set [dartx.a](value) {
      this.a = value;
    }
    get [dartx.b]() {
      return this.b;
    }
    set [dartx.b](value) {
      this.b = value;
    }
    get [dartx.c]() {
      return this.c;
    }
    set [dartx.c](value) {
      this.c = value;
    }
    get [dartx.d]() {
      return this.d;
    }
    set [dartx.d](value) {
      this.d = value;
    }
    get [dartx.e]() {
      return this.e;
    }
    set [dartx.e](value) {
      this.e = value;
    }
    get [dartx.f]() {
      return this.f;
    }
    set [dartx.f](value) {
      this.f = value;
    }
    [dartx.flipX]() {
      return this.flipX();
    }
    [dartx.flipY]() {
      return this.flipY();
    }
    [dartx.inverse]() {
      return this.inverse();
    }
    [dartx.multiply](secondMatrix) {
      return this.multiply(secondMatrix);
    }
    [dartx.rotate](angle) {
      return this.rotate(angle);
    }
    [dartx.rotateFromVector](x, y) {
      return this.rotateFromVector(x, y);
    }
    [dartx.scale](scaleFactor) {
      return this.scale(scaleFactor);
    }
    [dartx.scaleNonUniform](scaleFactorX, scaleFactorY) {
      return this.scaleNonUniform(scaleFactorX, scaleFactorY);
    }
    [dartx.skewX](angle) {
      return this.skewX(angle);
    }
    [dartx.skewY](angle) {
      return this.skewY(angle);
    }
    [dartx.translate](x, y) {
      return this.translate(x, y);
    }
  }
  dart.setSignature(Matrix, {
    constructors: () => ({_: [Matrix, []]}),
    methods: () => ({
      [dartx.flipX]: [Matrix, []],
      [dartx.flipY]: [Matrix, []],
      [dartx.inverse]: [Matrix, []],
      [dartx.multiply]: [Matrix, [Matrix]],
      [dartx.rotate]: [Matrix, [core.num]],
      [dartx.rotateFromVector]: [Matrix, [core.num, core.num]],
      [dartx.scale]: [Matrix, [core.num]],
      [dartx.scaleNonUniform]: [Matrix, [core.num, core.num]],
      [dartx.skewX]: [Matrix, [core.num]],
      [dartx.skewY]: [Matrix, [core.num]],
      [dartx.translate]: [Matrix, [core.num, core.num]]
    })
  });
  Matrix[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGMatrix')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGMatrix"))];
  dart.registerExtension(dart.global.SVGMatrix, Matrix);
  class MetadataElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      super.created();
    }
  }
  dart.defineNamedConstructor(MetadataElement, 'created');
  dart.setSignature(MetadataElement, {
    constructors: () => ({
      _: [MetadataElement, []],
      created: [MetadataElement, []]
    })
  });
  MetadataElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGMetadataElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGMetadataElement"))];
  dart.registerExtension(dart.global.SVGMetadataElement, MetadataElement);
  dart.defineExtensionNames([
    'value'
  ]);
  class Number extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.value]() {
      return this.value;
    }
    set [dartx.value](value) {
      this.value = value;
    }
  }
  dart.setSignature(Number, {
    constructors: () => ({_: [Number, []]})
  });
  Number[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGNumber')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGNumber"))];
  dart.registerExtension(dart.global.SVGNumber, Number);
  dart.defineExtensionNames([
    'length',
    'get',
    'set',
    'length',
    'first',
    'last',
    'single',
    'elementAt',
    'appendItem',
    'clear',
    'getItem',
    'initialize',
    'insertItemBefore',
    'removeItem',
    'replaceItem',
    'numberOfItems'
  ]);
  class NumberList extends dart.mixin(_interceptors.Interceptor, collection.ListMixin$(Number), html$.ImmutableListMixin$(Number)) {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.length]() {
      return this.length;
    }
    get [dartx.numberOfItems]() {
      return this.numberOfItems;
    }
    [dartx.get](index) {
      if (index >>> 0 !== index || index >= this[dartx.length]) dart.throw(core.RangeError.index(index, this));
      return this[dartx.getItem](index);
    }
    [dartx.set](index, value) {
      dart.throw(new core.UnsupportedError("Cannot assign element of immutable List."));
      return value;
    }
    set [dartx.length](value) {
      dart.throw(new core.UnsupportedError("Cannot resize immutable List."));
    }
    get [dartx.first]() {
      if (dart.notNull(this[dartx.length]) > 0) {
        return dart.as(this[0], Number);
      }
      dart.throw(new core.StateError("No elements"));
    }
    get [dartx.last]() {
      let len = this[dartx.length];
      if (dart.notNull(len) > 0) {
        return dart.as(this[dart.notNull(len) - 1], Number);
      }
      dart.throw(new core.StateError("No elements"));
    }
    get [dartx.single]() {
      let len = this[dartx.length];
      if (len == 1) {
        return dart.as(this[0], Number);
      }
      if (len == 0) dart.throw(new core.StateError("No elements"));
      dart.throw(new core.StateError("More than one element"));
    }
    [dartx.elementAt](index) {
      return this[dartx.get](index);
    }
    [__setter__](index, value) {
      return this.__setter__(index, value);
    }
    [dartx.appendItem](item) {
      return this.appendItem(item);
    }
    [dartx.clear]() {
      return this.clear();
    }
    [dartx.getItem](index) {
      return this.getItem(index);
    }
    [dartx.initialize](item) {
      return this.initialize(item);
    }
    [dartx.insertItemBefore](item, index) {
      return this.insertItemBefore(item, index);
    }
    [dartx.removeItem](index) {
      return this.removeItem(index);
    }
    [dartx.replaceItem](item, index) {
      return this.replaceItem(item, index);
    }
  }
  NumberList[dart.implements] = () => [core.List$(Number)];
  dart.setSignature(NumberList, {
    constructors: () => ({_: [NumberList, []]}),
    methods: () => ({
      [dartx.get]: [Number, [core.int]],
      [dartx.set]: [dart.void, [core.int, Number]],
      [dartx.elementAt]: [Number, [core.int]],
      [__setter__]: [dart.void, [core.int, Number]],
      [dartx.appendItem]: [Number, [Number]],
      [dartx.getItem]: [Number, [core.int]],
      [dartx.initialize]: [Number, [Number]],
      [dartx.insertItemBefore]: [Number, [Number, core.int]],
      [dartx.removeItem]: [Number, [core.int]],
      [dartx.replaceItem]: [Number, [Number, core.int]]
    })
  });
  NumberList[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGNumberList')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGNumberList"))];
  dart.registerExtension(dart.global.SVGNumberList, NumberList);
  dart.defineExtensionNames([
    'createSvgPathSegArcAbs',
    'createSvgPathSegArcRel',
    'createSvgPathSegClosePath',
    'createSvgPathSegCurvetoCubicAbs',
    'createSvgPathSegCurvetoCubicRel',
    'createSvgPathSegCurvetoCubicSmoothAbs',
    'createSvgPathSegCurvetoCubicSmoothRel',
    'createSvgPathSegCurvetoQuadraticAbs',
    'createSvgPathSegCurvetoQuadraticRel',
    'createSvgPathSegCurvetoQuadraticSmoothAbs',
    'createSvgPathSegCurvetoQuadraticSmoothRel',
    'createSvgPathSegLinetoAbs',
    'createSvgPathSegLinetoHorizontalAbs',
    'createSvgPathSegLinetoHorizontalRel',
    'createSvgPathSegLinetoRel',
    'createSvgPathSegLinetoVerticalAbs',
    'createSvgPathSegLinetoVerticalRel',
    'createSvgPathSegMovetoAbs',
    'createSvgPathSegMovetoRel',
    'getPathSegAtLength',
    'getPointAtLength',
    'getTotalLength',
    'animatedNormalizedPathSegList',
    'animatedPathSegList',
    'normalizedPathSegList',
    'pathLength',
    'pathSegList'
  ]);
  class PathElement extends GeometryElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("path"), PathElement);
    }
    created() {
      this[dartx.animatedNormalizedPathSegList] = null;
      this[dartx.animatedPathSegList] = null;
      this[dartx.normalizedPathSegList] = null;
      this[dartx.pathLength] = null;
      this[dartx.pathSegList] = null;
      super.created();
    }
    get [dartx.animatedNormalizedPathSegList]() {
      return this.animatedNormalizedPathSegList;
    }
    get [dartx.animatedPathSegList]() {
      return this.animatedPathSegList;
    }
    get [dartx.normalizedPathSegList]() {
      return this.normalizedPathSegList;
    }
    get [dartx.pathLength]() {
      return this.pathLength;
    }
    get [dartx.pathSegList]() {
      return this.pathSegList;
    }
    [dartx.createSvgPathSegArcAbs](x, y, r1, r2, angle, largeArcFlag, sweepFlag) {
      return this.createSVGPathSegArcAbs(x, y, r1, r2, angle, largeArcFlag, sweepFlag);
    }
    [dartx.createSvgPathSegArcRel](x, y, r1, r2, angle, largeArcFlag, sweepFlag) {
      return this.createSVGPathSegArcRel(x, y, r1, r2, angle, largeArcFlag, sweepFlag);
    }
    [dartx.createSvgPathSegClosePath]() {
      return this.createSVGPathSegClosePath();
    }
    [dartx.createSvgPathSegCurvetoCubicAbs](x, y, x1, y1, x2, y2) {
      return this.createSVGPathSegCurvetoCubicAbs(x, y, x1, y1, x2, y2);
    }
    [dartx.createSvgPathSegCurvetoCubicRel](x, y, x1, y1, x2, y2) {
      return this.createSVGPathSegCurvetoCubicRel(x, y, x1, y1, x2, y2);
    }
    [dartx.createSvgPathSegCurvetoCubicSmoothAbs](x, y, x2, y2) {
      return this.createSVGPathSegCurvetoCubicSmoothAbs(x, y, x2, y2);
    }
    [dartx.createSvgPathSegCurvetoCubicSmoothRel](x, y, x2, y2) {
      return this.createSVGPathSegCurvetoCubicSmoothRel(x, y, x2, y2);
    }
    [dartx.createSvgPathSegCurvetoQuadraticAbs](x, y, x1, y1) {
      return this.createSVGPathSegCurvetoQuadraticAbs(x, y, x1, y1);
    }
    [dartx.createSvgPathSegCurvetoQuadraticRel](x, y, x1, y1) {
      return this.createSVGPathSegCurvetoQuadraticRel(x, y, x1, y1);
    }
    [dartx.createSvgPathSegCurvetoQuadraticSmoothAbs](x, y) {
      return this.createSVGPathSegCurvetoQuadraticSmoothAbs(x, y);
    }
    [dartx.createSvgPathSegCurvetoQuadraticSmoothRel](x, y) {
      return this.createSVGPathSegCurvetoQuadraticSmoothRel(x, y);
    }
    [dartx.createSvgPathSegLinetoAbs](x, y) {
      return this.createSVGPathSegLinetoAbs(x, y);
    }
    [dartx.createSvgPathSegLinetoHorizontalAbs](x) {
      return this.createSVGPathSegLinetoHorizontalAbs(x);
    }
    [dartx.createSvgPathSegLinetoHorizontalRel](x) {
      return this.createSVGPathSegLinetoHorizontalRel(x);
    }
    [dartx.createSvgPathSegLinetoRel](x, y) {
      return this.createSVGPathSegLinetoRel(x, y);
    }
    [dartx.createSvgPathSegLinetoVerticalAbs](y) {
      return this.createSVGPathSegLinetoVerticalAbs(y);
    }
    [dartx.createSvgPathSegLinetoVerticalRel](y) {
      return this.createSVGPathSegLinetoVerticalRel(y);
    }
    [dartx.createSvgPathSegMovetoAbs](x, y) {
      return this.createSVGPathSegMovetoAbs(x, y);
    }
    [dartx.createSvgPathSegMovetoRel](x, y) {
      return this.createSVGPathSegMovetoRel(x, y);
    }
    [dartx.getPathSegAtLength](distance) {
      return this.getPathSegAtLength(distance);
    }
    [dartx.getPointAtLength](distance) {
      return this.getPointAtLength(distance);
    }
    [dartx.getTotalLength]() {
      return this.getTotalLength();
    }
  }
  dart.defineNamedConstructor(PathElement, 'created');
  dart.setSignature(PathElement, {
    constructors: () => ({
      _: [PathElement, []],
      new: [PathElement, []],
      created: [PathElement, []]
    }),
    methods: () => ({
      [dartx.createSvgPathSegArcAbs]: [PathSegArcAbs, [core.num, core.num, core.num, core.num, core.num, core.bool, core.bool]],
      [dartx.createSvgPathSegArcRel]: [PathSegArcRel, [core.num, core.num, core.num, core.num, core.num, core.bool, core.bool]],
      [dartx.createSvgPathSegClosePath]: [PathSegClosePath, []],
      [dartx.createSvgPathSegCurvetoCubicAbs]: [PathSegCurvetoCubicAbs, [core.num, core.num, core.num, core.num, core.num, core.num]],
      [dartx.createSvgPathSegCurvetoCubicRel]: [PathSegCurvetoCubicRel, [core.num, core.num, core.num, core.num, core.num, core.num]],
      [dartx.createSvgPathSegCurvetoCubicSmoothAbs]: [PathSegCurvetoCubicSmoothAbs, [core.num, core.num, core.num, core.num]],
      [dartx.createSvgPathSegCurvetoCubicSmoothRel]: [PathSegCurvetoCubicSmoothRel, [core.num, core.num, core.num, core.num]],
      [dartx.createSvgPathSegCurvetoQuadraticAbs]: [PathSegCurvetoQuadraticAbs, [core.num, core.num, core.num, core.num]],
      [dartx.createSvgPathSegCurvetoQuadraticRel]: [PathSegCurvetoQuadraticRel, [core.num, core.num, core.num, core.num]],
      [dartx.createSvgPathSegCurvetoQuadraticSmoothAbs]: [PathSegCurvetoQuadraticSmoothAbs, [core.num, core.num]],
      [dartx.createSvgPathSegCurvetoQuadraticSmoothRel]: [PathSegCurvetoQuadraticSmoothRel, [core.num, core.num]],
      [dartx.createSvgPathSegLinetoAbs]: [PathSegLinetoAbs, [core.num, core.num]],
      [dartx.createSvgPathSegLinetoHorizontalAbs]: [PathSegLinetoHorizontalAbs, [core.num]],
      [dartx.createSvgPathSegLinetoHorizontalRel]: [PathSegLinetoHorizontalRel, [core.num]],
      [dartx.createSvgPathSegLinetoRel]: [PathSegLinetoRel, [core.num, core.num]],
      [dartx.createSvgPathSegLinetoVerticalAbs]: [PathSegLinetoVerticalAbs, [core.num]],
      [dartx.createSvgPathSegLinetoVerticalRel]: [PathSegLinetoVerticalRel, [core.num]],
      [dartx.createSvgPathSegMovetoAbs]: [PathSegMovetoAbs, [core.num, core.num]],
      [dartx.createSvgPathSegMovetoRel]: [PathSegMovetoRel, [core.num, core.num]],
      [dartx.getPathSegAtLength]: [core.int, [core.num]],
      [dartx.getPointAtLength]: [Point, [core.num]],
      [dartx.getTotalLength]: [core.double, []]
    })
  });
  PathElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPathElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPathElement"))];
  dart.registerExtension(dart.global.SVGPathElement, PathElement);
  dart.defineExtensionNames([
    'pathSegType',
    'pathSegTypeAsLetter'
  ]);
  class PathSeg extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.pathSegType]() {
      return this.pathSegType;
    }
    get [dartx.pathSegTypeAsLetter]() {
      return this.pathSegTypeAsLetter;
    }
  }
  dart.setSignature(PathSeg, {
    constructors: () => ({_: [PathSeg, []]})
  });
  PathSeg[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPathSeg')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPathSeg"))];
  PathSeg.PATHSEG_ARC_ABS = 10;
  PathSeg.PATHSEG_ARC_REL = 11;
  PathSeg.PATHSEG_CLOSEPATH = 1;
  PathSeg.PATHSEG_CURVETO_CUBIC_ABS = 6;
  PathSeg.PATHSEG_CURVETO_CUBIC_REL = 7;
  PathSeg.PATHSEG_CURVETO_CUBIC_SMOOTH_ABS = 16;
  PathSeg.PATHSEG_CURVETO_CUBIC_SMOOTH_REL = 17;
  PathSeg.PATHSEG_CURVETO_QUADRATIC_ABS = 8;
  PathSeg.PATHSEG_CURVETO_QUADRATIC_REL = 9;
  PathSeg.PATHSEG_CURVETO_QUADRATIC_SMOOTH_ABS = 18;
  PathSeg.PATHSEG_CURVETO_QUADRATIC_SMOOTH_REL = 19;
  PathSeg.PATHSEG_LINETO_ABS = 4;
  PathSeg.PATHSEG_LINETO_HORIZONTAL_ABS = 12;
  PathSeg.PATHSEG_LINETO_HORIZONTAL_REL = 13;
  PathSeg.PATHSEG_LINETO_REL = 5;
  PathSeg.PATHSEG_LINETO_VERTICAL_ABS = 14;
  PathSeg.PATHSEG_LINETO_VERTICAL_REL = 15;
  PathSeg.PATHSEG_MOVETO_ABS = 2;
  PathSeg.PATHSEG_MOVETO_REL = 3;
  PathSeg.PATHSEG_UNKNOWN = 0;
  dart.registerExtension(dart.global.SVGPathSeg, PathSeg);
  dart.defineExtensionNames([
    'angle',
    'largeArcFlag',
    'r1',
    'r2',
    'sweepFlag',
    'x',
    'y'
  ]);
  class PathSegArcAbs extends PathSeg {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.angle]() {
      return this.angle;
    }
    set [dartx.angle](value) {
      this.angle = value;
    }
    get [dartx.largeArcFlag]() {
      return this.largeArcFlag;
    }
    set [dartx.largeArcFlag](value) {
      this.largeArcFlag = value;
    }
    get [dartx.r1]() {
      return this.r1;
    }
    set [dartx.r1](value) {
      this.r1 = value;
    }
    get [dartx.r2]() {
      return this.r2;
    }
    set [dartx.r2](value) {
      this.r2 = value;
    }
    get [dartx.sweepFlag]() {
      return this.sweepFlag;
    }
    set [dartx.sweepFlag](value) {
      this.sweepFlag = value;
    }
    get [dartx.x]() {
      return this.x;
    }
    set [dartx.x](value) {
      this.x = value;
    }
    get [dartx.y]() {
      return this.y;
    }
    set [dartx.y](value) {
      this.y = value;
    }
  }
  dart.setSignature(PathSegArcAbs, {
    constructors: () => ({_: [PathSegArcAbs, []]})
  });
  PathSegArcAbs[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPathSegArcAbs')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPathSegArcAbs"))];
  dart.registerExtension(dart.global.SVGPathSegArcAbs, PathSegArcAbs);
  dart.defineExtensionNames([
    'angle',
    'largeArcFlag',
    'r1',
    'r2',
    'sweepFlag',
    'x',
    'y'
  ]);
  class PathSegArcRel extends PathSeg {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.angle]() {
      return this.angle;
    }
    set [dartx.angle](value) {
      this.angle = value;
    }
    get [dartx.largeArcFlag]() {
      return this.largeArcFlag;
    }
    set [dartx.largeArcFlag](value) {
      this.largeArcFlag = value;
    }
    get [dartx.r1]() {
      return this.r1;
    }
    set [dartx.r1](value) {
      this.r1 = value;
    }
    get [dartx.r2]() {
      return this.r2;
    }
    set [dartx.r2](value) {
      this.r2 = value;
    }
    get [dartx.sweepFlag]() {
      return this.sweepFlag;
    }
    set [dartx.sweepFlag](value) {
      this.sweepFlag = value;
    }
    get [dartx.x]() {
      return this.x;
    }
    set [dartx.x](value) {
      this.x = value;
    }
    get [dartx.y]() {
      return this.y;
    }
    set [dartx.y](value) {
      this.y = value;
    }
  }
  dart.setSignature(PathSegArcRel, {
    constructors: () => ({_: [PathSegArcRel, []]})
  });
  PathSegArcRel[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPathSegArcRel')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPathSegArcRel"))];
  dart.registerExtension(dart.global.SVGPathSegArcRel, PathSegArcRel);
  class PathSegClosePath extends PathSeg {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(PathSegClosePath, {
    constructors: () => ({_: [PathSegClosePath, []]})
  });
  PathSegClosePath[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPathSegClosePath')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPathSegClosePath"))];
  dart.registerExtension(dart.global.SVGPathSegClosePath, PathSegClosePath);
  dart.defineExtensionNames([
    'x',
    'x1',
    'x2',
    'y',
    'y1',
    'y2'
  ]);
  class PathSegCurvetoCubicAbs extends PathSeg {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.x]() {
      return this.x;
    }
    set [dartx.x](value) {
      this.x = value;
    }
    get [dartx.x1]() {
      return this.x1;
    }
    set [dartx.x1](value) {
      this.x1 = value;
    }
    get [dartx.x2]() {
      return this.x2;
    }
    set [dartx.x2](value) {
      this.x2 = value;
    }
    get [dartx.y]() {
      return this.y;
    }
    set [dartx.y](value) {
      this.y = value;
    }
    get [dartx.y1]() {
      return this.y1;
    }
    set [dartx.y1](value) {
      this.y1 = value;
    }
    get [dartx.y2]() {
      return this.y2;
    }
    set [dartx.y2](value) {
      this.y2 = value;
    }
  }
  dart.setSignature(PathSegCurvetoCubicAbs, {
    constructors: () => ({_: [PathSegCurvetoCubicAbs, []]})
  });
  PathSegCurvetoCubicAbs[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPathSegCurvetoCubicAbs')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPathSegCurvetoCubicAbs"))];
  dart.registerExtension(dart.global.SVGPathSegCurvetoCubicAbs, PathSegCurvetoCubicAbs);
  dart.defineExtensionNames([
    'x',
    'x1',
    'x2',
    'y',
    'y1',
    'y2'
  ]);
  class PathSegCurvetoCubicRel extends PathSeg {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.x]() {
      return this.x;
    }
    set [dartx.x](value) {
      this.x = value;
    }
    get [dartx.x1]() {
      return this.x1;
    }
    set [dartx.x1](value) {
      this.x1 = value;
    }
    get [dartx.x2]() {
      return this.x2;
    }
    set [dartx.x2](value) {
      this.x2 = value;
    }
    get [dartx.y]() {
      return this.y;
    }
    set [dartx.y](value) {
      this.y = value;
    }
    get [dartx.y1]() {
      return this.y1;
    }
    set [dartx.y1](value) {
      this.y1 = value;
    }
    get [dartx.y2]() {
      return this.y2;
    }
    set [dartx.y2](value) {
      this.y2 = value;
    }
  }
  dart.setSignature(PathSegCurvetoCubicRel, {
    constructors: () => ({_: [PathSegCurvetoCubicRel, []]})
  });
  PathSegCurvetoCubicRel[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPathSegCurvetoCubicRel')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPathSegCurvetoCubicRel"))];
  dart.registerExtension(dart.global.SVGPathSegCurvetoCubicRel, PathSegCurvetoCubicRel);
  dart.defineExtensionNames([
    'x',
    'x2',
    'y',
    'y2'
  ]);
  class PathSegCurvetoCubicSmoothAbs extends PathSeg {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.x]() {
      return this.x;
    }
    set [dartx.x](value) {
      this.x = value;
    }
    get [dartx.x2]() {
      return this.x2;
    }
    set [dartx.x2](value) {
      this.x2 = value;
    }
    get [dartx.y]() {
      return this.y;
    }
    set [dartx.y](value) {
      this.y = value;
    }
    get [dartx.y2]() {
      return this.y2;
    }
    set [dartx.y2](value) {
      this.y2 = value;
    }
  }
  dart.setSignature(PathSegCurvetoCubicSmoothAbs, {
    constructors: () => ({_: [PathSegCurvetoCubicSmoothAbs, []]})
  });
  PathSegCurvetoCubicSmoothAbs[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPathSegCurvetoCubicSmoothAbs')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPathSegCurvetoCubicSmoothAbs"))];
  dart.registerExtension(dart.global.SVGPathSegCurvetoCubicSmoothAbs, PathSegCurvetoCubicSmoothAbs);
  dart.defineExtensionNames([
    'x',
    'x2',
    'y',
    'y2'
  ]);
  class PathSegCurvetoCubicSmoothRel extends PathSeg {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.x]() {
      return this.x;
    }
    set [dartx.x](value) {
      this.x = value;
    }
    get [dartx.x2]() {
      return this.x2;
    }
    set [dartx.x2](value) {
      this.x2 = value;
    }
    get [dartx.y]() {
      return this.y;
    }
    set [dartx.y](value) {
      this.y = value;
    }
    get [dartx.y2]() {
      return this.y2;
    }
    set [dartx.y2](value) {
      this.y2 = value;
    }
  }
  dart.setSignature(PathSegCurvetoCubicSmoothRel, {
    constructors: () => ({_: [PathSegCurvetoCubicSmoothRel, []]})
  });
  PathSegCurvetoCubicSmoothRel[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPathSegCurvetoCubicSmoothRel')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPathSegCurvetoCubicSmoothRel"))];
  dart.registerExtension(dart.global.SVGPathSegCurvetoCubicSmoothRel, PathSegCurvetoCubicSmoothRel);
  dart.defineExtensionNames([
    'x',
    'x1',
    'y',
    'y1'
  ]);
  class PathSegCurvetoQuadraticAbs extends PathSeg {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.x]() {
      return this.x;
    }
    set [dartx.x](value) {
      this.x = value;
    }
    get [dartx.x1]() {
      return this.x1;
    }
    set [dartx.x1](value) {
      this.x1 = value;
    }
    get [dartx.y]() {
      return this.y;
    }
    set [dartx.y](value) {
      this.y = value;
    }
    get [dartx.y1]() {
      return this.y1;
    }
    set [dartx.y1](value) {
      this.y1 = value;
    }
  }
  dart.setSignature(PathSegCurvetoQuadraticAbs, {
    constructors: () => ({_: [PathSegCurvetoQuadraticAbs, []]})
  });
  PathSegCurvetoQuadraticAbs[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPathSegCurvetoQuadraticAbs')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPathSegCurvetoQuadraticAbs"))];
  dart.registerExtension(dart.global.SVGPathSegCurvetoQuadraticAbs, PathSegCurvetoQuadraticAbs);
  dart.defineExtensionNames([
    'x',
    'x1',
    'y',
    'y1'
  ]);
  class PathSegCurvetoQuadraticRel extends PathSeg {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.x]() {
      return this.x;
    }
    set [dartx.x](value) {
      this.x = value;
    }
    get [dartx.x1]() {
      return this.x1;
    }
    set [dartx.x1](value) {
      this.x1 = value;
    }
    get [dartx.y]() {
      return this.y;
    }
    set [dartx.y](value) {
      this.y = value;
    }
    get [dartx.y1]() {
      return this.y1;
    }
    set [dartx.y1](value) {
      this.y1 = value;
    }
  }
  dart.setSignature(PathSegCurvetoQuadraticRel, {
    constructors: () => ({_: [PathSegCurvetoQuadraticRel, []]})
  });
  PathSegCurvetoQuadraticRel[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPathSegCurvetoQuadraticRel')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPathSegCurvetoQuadraticRel"))];
  dart.registerExtension(dart.global.SVGPathSegCurvetoQuadraticRel, PathSegCurvetoQuadraticRel);
  dart.defineExtensionNames([
    'x',
    'y'
  ]);
  class PathSegCurvetoQuadraticSmoothAbs extends PathSeg {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.x]() {
      return this.x;
    }
    set [dartx.x](value) {
      this.x = value;
    }
    get [dartx.y]() {
      return this.y;
    }
    set [dartx.y](value) {
      this.y = value;
    }
  }
  dart.setSignature(PathSegCurvetoQuadraticSmoothAbs, {
    constructors: () => ({_: [PathSegCurvetoQuadraticSmoothAbs, []]})
  });
  PathSegCurvetoQuadraticSmoothAbs[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPathSegCurvetoQuadraticSmoothAbs')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPathSegCurvetoQuadraticSmoothAbs"))];
  dart.registerExtension(dart.global.SVGPathSegCurvetoQuadraticSmoothAbs, PathSegCurvetoQuadraticSmoothAbs);
  dart.defineExtensionNames([
    'x',
    'y'
  ]);
  class PathSegCurvetoQuadraticSmoothRel extends PathSeg {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.x]() {
      return this.x;
    }
    set [dartx.x](value) {
      this.x = value;
    }
    get [dartx.y]() {
      return this.y;
    }
    set [dartx.y](value) {
      this.y = value;
    }
  }
  dart.setSignature(PathSegCurvetoQuadraticSmoothRel, {
    constructors: () => ({_: [PathSegCurvetoQuadraticSmoothRel, []]})
  });
  PathSegCurvetoQuadraticSmoothRel[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPathSegCurvetoQuadraticSmoothRel')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPathSegCurvetoQuadraticSmoothRel"))];
  dart.registerExtension(dart.global.SVGPathSegCurvetoQuadraticSmoothRel, PathSegCurvetoQuadraticSmoothRel);
  dart.defineExtensionNames([
    'x',
    'y'
  ]);
  class PathSegLinetoAbs extends PathSeg {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.x]() {
      return this.x;
    }
    set [dartx.x](value) {
      this.x = value;
    }
    get [dartx.y]() {
      return this.y;
    }
    set [dartx.y](value) {
      this.y = value;
    }
  }
  dart.setSignature(PathSegLinetoAbs, {
    constructors: () => ({_: [PathSegLinetoAbs, []]})
  });
  PathSegLinetoAbs[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPathSegLinetoAbs')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPathSegLinetoAbs"))];
  dart.registerExtension(dart.global.SVGPathSegLinetoAbs, PathSegLinetoAbs);
  dart.defineExtensionNames([
    'x'
  ]);
  class PathSegLinetoHorizontalAbs extends PathSeg {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.x]() {
      return this.x;
    }
    set [dartx.x](value) {
      this.x = value;
    }
  }
  dart.setSignature(PathSegLinetoHorizontalAbs, {
    constructors: () => ({_: [PathSegLinetoHorizontalAbs, []]})
  });
  PathSegLinetoHorizontalAbs[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPathSegLinetoHorizontalAbs')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPathSegLinetoHorizontalAbs"))];
  dart.registerExtension(dart.global.SVGPathSegLinetoHorizontalAbs, PathSegLinetoHorizontalAbs);
  dart.defineExtensionNames([
    'x'
  ]);
  class PathSegLinetoHorizontalRel extends PathSeg {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.x]() {
      return this.x;
    }
    set [dartx.x](value) {
      this.x = value;
    }
  }
  dart.setSignature(PathSegLinetoHorizontalRel, {
    constructors: () => ({_: [PathSegLinetoHorizontalRel, []]})
  });
  PathSegLinetoHorizontalRel[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPathSegLinetoHorizontalRel')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPathSegLinetoHorizontalRel"))];
  dart.registerExtension(dart.global.SVGPathSegLinetoHorizontalRel, PathSegLinetoHorizontalRel);
  dart.defineExtensionNames([
    'x',
    'y'
  ]);
  class PathSegLinetoRel extends PathSeg {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.x]() {
      return this.x;
    }
    set [dartx.x](value) {
      this.x = value;
    }
    get [dartx.y]() {
      return this.y;
    }
    set [dartx.y](value) {
      this.y = value;
    }
  }
  dart.setSignature(PathSegLinetoRel, {
    constructors: () => ({_: [PathSegLinetoRel, []]})
  });
  PathSegLinetoRel[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPathSegLinetoRel')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPathSegLinetoRel"))];
  dart.registerExtension(dart.global.SVGPathSegLinetoRel, PathSegLinetoRel);
  dart.defineExtensionNames([
    'y'
  ]);
  class PathSegLinetoVerticalAbs extends PathSeg {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.y]() {
      return this.y;
    }
    set [dartx.y](value) {
      this.y = value;
    }
  }
  dart.setSignature(PathSegLinetoVerticalAbs, {
    constructors: () => ({_: [PathSegLinetoVerticalAbs, []]})
  });
  PathSegLinetoVerticalAbs[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPathSegLinetoVerticalAbs')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPathSegLinetoVerticalAbs"))];
  dart.registerExtension(dart.global.SVGPathSegLinetoVerticalAbs, PathSegLinetoVerticalAbs);
  dart.defineExtensionNames([
    'y'
  ]);
  class PathSegLinetoVerticalRel extends PathSeg {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.y]() {
      return this.y;
    }
    set [dartx.y](value) {
      this.y = value;
    }
  }
  dart.setSignature(PathSegLinetoVerticalRel, {
    constructors: () => ({_: [PathSegLinetoVerticalRel, []]})
  });
  PathSegLinetoVerticalRel[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPathSegLinetoVerticalRel')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPathSegLinetoVerticalRel"))];
  dart.registerExtension(dart.global.SVGPathSegLinetoVerticalRel, PathSegLinetoVerticalRel);
  dart.defineExtensionNames([
    'length',
    'get',
    'set',
    'length',
    'first',
    'last',
    'single',
    'elementAt',
    'appendItem',
    'clear',
    'getItem',
    'initialize',
    'insertItemBefore',
    'removeItem',
    'replaceItem',
    'numberOfItems'
  ]);
  class PathSegList extends dart.mixin(_interceptors.Interceptor, collection.ListMixin$(PathSeg), html$.ImmutableListMixin$(PathSeg)) {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.length]() {
      return this.length;
    }
    get [dartx.numberOfItems]() {
      return this.numberOfItems;
    }
    [dartx.get](index) {
      if (index >>> 0 !== index || index >= this[dartx.length]) dart.throw(core.RangeError.index(index, this));
      return this[dartx.getItem](index);
    }
    [dartx.set](index, value) {
      dart.throw(new core.UnsupportedError("Cannot assign element of immutable List."));
      return value;
    }
    set [dartx.length](value) {
      dart.throw(new core.UnsupportedError("Cannot resize immutable List."));
    }
    get [dartx.first]() {
      if (dart.notNull(this[dartx.length]) > 0) {
        return dart.as(this[0], PathSeg);
      }
      dart.throw(new core.StateError("No elements"));
    }
    get [dartx.last]() {
      let len = this[dartx.length];
      if (dart.notNull(len) > 0) {
        return dart.as(this[dart.notNull(len) - 1], PathSeg);
      }
      dart.throw(new core.StateError("No elements"));
    }
    get [dartx.single]() {
      let len = this[dartx.length];
      if (len == 1) {
        return dart.as(this[0], PathSeg);
      }
      if (len == 0) dart.throw(new core.StateError("No elements"));
      dart.throw(new core.StateError("More than one element"));
    }
    [dartx.elementAt](index) {
      return this[dartx.get](index);
    }
    [__setter__](index, value) {
      return this.__setter__(index, value);
    }
    [dartx.appendItem](newItem) {
      return this.appendItem(newItem);
    }
    [dartx.clear]() {
      return this.clear();
    }
    [dartx.getItem](index) {
      return this.getItem(index);
    }
    [dartx.initialize](newItem) {
      return this.initialize(newItem);
    }
    [dartx.insertItemBefore](newItem, index) {
      return this.insertItemBefore(newItem, index);
    }
    [dartx.removeItem](index) {
      return this.removeItem(index);
    }
    [dartx.replaceItem](newItem, index) {
      return this.replaceItem(newItem, index);
    }
  }
  PathSegList[dart.implements] = () => [core.List$(PathSeg)];
  dart.setSignature(PathSegList, {
    constructors: () => ({_: [PathSegList, []]}),
    methods: () => ({
      [dartx.get]: [PathSeg, [core.int]],
      [dartx.set]: [dart.void, [core.int, PathSeg]],
      [dartx.elementAt]: [PathSeg, [core.int]],
      [__setter__]: [dart.void, [core.int, PathSeg]],
      [dartx.appendItem]: [PathSeg, [PathSeg]],
      [dartx.getItem]: [PathSeg, [core.int]],
      [dartx.initialize]: [PathSeg, [PathSeg]],
      [dartx.insertItemBefore]: [PathSeg, [PathSeg, core.int]],
      [dartx.removeItem]: [PathSeg, [core.int]],
      [dartx.replaceItem]: [PathSeg, [PathSeg, core.int]]
    })
  });
  PathSegList[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPathSegList')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPathSegList"))];
  dart.registerExtension(dart.global.SVGPathSegList, PathSegList);
  dart.defineExtensionNames([
    'x',
    'y'
  ]);
  class PathSegMovetoAbs extends PathSeg {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.x]() {
      return this.x;
    }
    set [dartx.x](value) {
      this.x = value;
    }
    get [dartx.y]() {
      return this.y;
    }
    set [dartx.y](value) {
      this.y = value;
    }
  }
  dart.setSignature(PathSegMovetoAbs, {
    constructors: () => ({_: [PathSegMovetoAbs, []]})
  });
  PathSegMovetoAbs[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPathSegMovetoAbs')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPathSegMovetoAbs"))];
  dart.registerExtension(dart.global.SVGPathSegMovetoAbs, PathSegMovetoAbs);
  dart.defineExtensionNames([
    'x',
    'y'
  ]);
  class PathSegMovetoRel extends PathSeg {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.x]() {
      return this.x;
    }
    set [dartx.x](value) {
      this.x = value;
    }
    get [dartx.y]() {
      return this.y;
    }
    set [dartx.y](value) {
      this.y = value;
    }
  }
  dart.setSignature(PathSegMovetoRel, {
    constructors: () => ({_: [PathSegMovetoRel, []]})
  });
  PathSegMovetoRel[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPathSegMovetoRel')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPathSegMovetoRel"))];
  dart.registerExtension(dart.global.SVGPathSegMovetoRel, PathSegMovetoRel);
  dart.defineExtensionNames([
    'hasExtension',
    'height',
    'patternContentUnits',
    'patternTransform',
    'patternUnits',
    'width',
    'x',
    'y',
    'preserveAspectRatio',
    'viewBox',
    'requiredExtensions',
    'requiredFeatures',
    'systemLanguage',
    'href'
  ]);
  class PatternElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("pattern"), PatternElement);
    }
    created() {
      this[dartx.height] = null;
      this[dartx.patternContentUnits] = null;
      this[dartx.patternTransform] = null;
      this[dartx.patternUnits] = null;
      this[dartx.width] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      this[dartx.preserveAspectRatio] = null;
      this[dartx.viewBox] = null;
      this[dartx.requiredExtensions] = null;
      this[dartx.requiredFeatures] = null;
      this[dartx.systemLanguage] = null;
      this[dartx.href] = null;
      super.created();
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.patternContentUnits]() {
      return this.patternContentUnits;
    }
    get [dartx.patternTransform]() {
      return this.patternTransform;
    }
    get [dartx.patternUnits]() {
      return this.patternUnits;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
    get [dartx.preserveAspectRatio]() {
      return this.preserveAspectRatio;
    }
    get [dartx.viewBox]() {
      return this.viewBox;
    }
    get [dartx.requiredExtensions]() {
      return this.requiredExtensions;
    }
    get [dartx.requiredFeatures]() {
      return this.requiredFeatures;
    }
    get [dartx.systemLanguage]() {
      return this.systemLanguage;
    }
    [dartx.hasExtension](extension) {
      return this.hasExtension(extension);
    }
    get [dartx.href]() {
      return this.href;
    }
  }
  PatternElement[dart.implements] = () => [FitToViewBox, UriReference, Tests];
  dart.defineNamedConstructor(PatternElement, 'created');
  dart.setSignature(PatternElement, {
    constructors: () => ({
      _: [PatternElement, []],
      new: [PatternElement, []],
      created: [PatternElement, []]
    }),
    methods: () => ({[dartx.hasExtension]: [core.bool, [core.String]]})
  });
  PatternElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPatternElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPatternElement"))];
  dart.registerExtension(dart.global.SVGPatternElement, PatternElement);
  dart.defineExtensionNames([
    'matrixTransform',
    'x',
    'y'
  ]);
  class Point extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.x]() {
      return this.x;
    }
    set [dartx.x](value) {
      this.x = value;
    }
    get [dartx.y]() {
      return this.y;
    }
    set [dartx.y](value) {
      this.y = value;
    }
    [dartx.matrixTransform](matrix) {
      return this.matrixTransform(matrix);
    }
  }
  dart.setSignature(Point, {
    constructors: () => ({_: [Point, []]}),
    methods: () => ({[dartx.matrixTransform]: [Point, [Matrix]]})
  });
  Point[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPoint')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPoint"))];
  dart.registerExtension(dart.global.SVGPoint, Point);
  dart.defineExtensionNames([
    'appendItem',
    'clear',
    'getItem',
    'initialize',
    'insertItemBefore',
    'removeItem',
    'replaceItem',
    'length',
    'numberOfItems'
  ]);
  class PointList extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.length]() {
      return this.length;
    }
    get [dartx.numberOfItems]() {
      return this.numberOfItems;
    }
    [__setter__](index, value) {
      return this.__setter__(index, value);
    }
    [dartx.appendItem](item) {
      return this.appendItem(item);
    }
    [dartx.clear]() {
      return this.clear();
    }
    [dartx.getItem](index) {
      return this.getItem(index);
    }
    [dartx.initialize](item) {
      return this.initialize(item);
    }
    [dartx.insertItemBefore](item, index) {
      return this.insertItemBefore(item, index);
    }
    [dartx.removeItem](index) {
      return this.removeItem(index);
    }
    [dartx.replaceItem](item, index) {
      return this.replaceItem(item, index);
    }
  }
  dart.setSignature(PointList, {
    constructors: () => ({_: [PointList, []]}),
    methods: () => ({
      [__setter__]: [dart.void, [core.int, Point]],
      [dartx.appendItem]: [Point, [Point]],
      [dartx.clear]: [dart.void, []],
      [dartx.getItem]: [Point, [core.int]],
      [dartx.initialize]: [Point, [Point]],
      [dartx.insertItemBefore]: [Point, [Point, core.int]],
      [dartx.removeItem]: [Point, [core.int]],
      [dartx.replaceItem]: [Point, [Point, core.int]]
    })
  });
  PointList[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPointList')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPointList"))];
  dart.registerExtension(dart.global.SVGPointList, PointList);
  dart.defineExtensionNames([
    'animatedPoints',
    'points'
  ]);
  class PolygonElement extends GeometryElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("polygon"), PolygonElement);
    }
    created() {
      this[dartx.animatedPoints] = null;
      this[dartx.points] = null;
      super.created();
    }
    get [dartx.animatedPoints]() {
      return this.animatedPoints;
    }
    get [dartx.points]() {
      return this.points;
    }
  }
  dart.defineNamedConstructor(PolygonElement, 'created');
  dart.setSignature(PolygonElement, {
    constructors: () => ({
      _: [PolygonElement, []],
      new: [PolygonElement, []],
      created: [PolygonElement, []]
    })
  });
  PolygonElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPolygonElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPolygonElement"))];
  dart.registerExtension(dart.global.SVGPolygonElement, PolygonElement);
  dart.defineExtensionNames([
    'animatedPoints',
    'points'
  ]);
  class PolylineElement extends GeometryElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("polyline"), PolylineElement);
    }
    created() {
      this[dartx.animatedPoints] = null;
      this[dartx.points] = null;
      super.created();
    }
    get [dartx.animatedPoints]() {
      return this.animatedPoints;
    }
    get [dartx.points]() {
      return this.points;
    }
  }
  dart.defineNamedConstructor(PolylineElement, 'created');
  dart.setSignature(PolylineElement, {
    constructors: () => ({
      _: [PolylineElement, []],
      new: [PolylineElement, []],
      created: [PolylineElement, []]
    })
  });
  PolylineElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPolylineElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPolylineElement"))];
  dart.registerExtension(dart.global.SVGPolylineElement, PolylineElement);
  dart.defineExtensionNames([
    'align',
    'meetOrSlice'
  ]);
  class PreserveAspectRatio extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.align]() {
      return this.align;
    }
    set [dartx.align](value) {
      this.align = value;
    }
    get [dartx.meetOrSlice]() {
      return this.meetOrSlice;
    }
    set [dartx.meetOrSlice](value) {
      this.meetOrSlice = value;
    }
  }
  dart.setSignature(PreserveAspectRatio, {
    constructors: () => ({_: [PreserveAspectRatio, []]})
  });
  PreserveAspectRatio[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGPreserveAspectRatio')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGPreserveAspectRatio"))];
  PreserveAspectRatio.SVG_MEETORSLICE_MEET = 1;
  PreserveAspectRatio.SVG_MEETORSLICE_SLICE = 2;
  PreserveAspectRatio.SVG_MEETORSLICE_UNKNOWN = 0;
  PreserveAspectRatio.SVG_PRESERVEASPECTRATIO_NONE = 1;
  PreserveAspectRatio.SVG_PRESERVEASPECTRATIO_UNKNOWN = 0;
  PreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMAXYMAX = 10;
  PreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMAXYMID = 7;
  PreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMAXYMIN = 4;
  PreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMIDYMAX = 9;
  PreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMIDYMID = 6;
  PreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMIDYMIN = 3;
  PreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMINYMAX = 8;
  PreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMINYMID = 5;
  PreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMINYMIN = 2;
  dart.registerExtension(dart.global.SVGPreserveAspectRatio, PreserveAspectRatio);
  dart.defineExtensionNames([
    'cx',
    'cy',
    'fr',
    'fx',
    'fy',
    'r'
  ]);
  class RadialGradientElement extends _GradientElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("radialGradient"), RadialGradientElement);
    }
    created() {
      this[dartx.cx] = null;
      this[dartx.cy] = null;
      this[dartx.fr] = null;
      this[dartx.fx] = null;
      this[dartx.fy] = null;
      this[dartx.r] = null;
      super.created();
    }
    get [dartx.cx]() {
      return this.cx;
    }
    get [dartx.cy]() {
      return this.cy;
    }
    get [dartx.fr]() {
      return this.fr;
    }
    get [dartx.fx]() {
      return this.fx;
    }
    get [dartx.fy]() {
      return this.fy;
    }
    get [dartx.r]() {
      return this.r;
    }
  }
  dart.defineNamedConstructor(RadialGradientElement, 'created');
  dart.setSignature(RadialGradientElement, {
    constructors: () => ({
      _: [RadialGradientElement, []],
      new: [RadialGradientElement, []],
      created: [RadialGradientElement, []]
    })
  });
  RadialGradientElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGRadialGradientElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGRadialGradientElement"))];
  dart.registerExtension(dart.global.SVGRadialGradientElement, RadialGradientElement);
  dart.defineExtensionNames([
    'height',
    'width',
    'x',
    'y'
  ]);
  class Rect extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.height]() {
      return this.height;
    }
    set [dartx.height](value) {
      this.height = value;
    }
    get [dartx.width]() {
      return this.width;
    }
    set [dartx.width](value) {
      this.width = value;
    }
    get [dartx.x]() {
      return this.x;
    }
    set [dartx.x](value) {
      this.x = value;
    }
    get [dartx.y]() {
      return this.y;
    }
    set [dartx.y](value) {
      this.y = value;
    }
  }
  dart.setSignature(Rect, {
    constructors: () => ({_: [Rect, []]})
  });
  Rect[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGRect')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGRect"))];
  dart.registerExtension(dart.global.SVGRect, Rect);
  dart.defineExtensionNames([
    'height',
    'rx',
    'ry',
    'width',
    'x',
    'y'
  ]);
  class RectElement extends GeometryElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("rect"), RectElement);
    }
    created() {
      this[dartx.height] = null;
      this[dartx.rx] = null;
      this[dartx.ry] = null;
      this[dartx.width] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      super.created();
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.rx]() {
      return this.rx;
    }
    get [dartx.ry]() {
      return this.ry;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
  }
  dart.defineNamedConstructor(RectElement, 'created');
  dart.setSignature(RectElement, {
    constructors: () => ({
      _: [RectElement, []],
      new: [RectElement, []],
      created: [RectElement, []]
    })
  });
  RectElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGRectElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGRectElement"))];
  dart.registerExtension(dart.global.SVGRectElement, RectElement);
  class RenderingIntent extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(RenderingIntent, {
    constructors: () => ({_: [RenderingIntent, []]})
  });
  RenderingIntent[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGRenderingIntent')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGRenderingIntent"))];
  RenderingIntent.RENDERING_INTENT_ABSOLUTE_COLORIMETRIC = 5;
  RenderingIntent.RENDERING_INTENT_AUTO = 1;
  RenderingIntent.RENDERING_INTENT_PERCEPTUAL = 2;
  RenderingIntent.RENDERING_INTENT_RELATIVE_COLORIMETRIC = 3;
  RenderingIntent.RENDERING_INTENT_SATURATION = 4;
  RenderingIntent.RENDERING_INTENT_UNKNOWN = 0;
  dart.registerExtension(dart.global.SVGRenderingIntent, RenderingIntent);
  dart.defineExtensionNames([
    'type',
    'href'
  ]);
  class ScriptElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("script"), ScriptElement);
    }
    created() {
      this[dartx.type] = null;
      this[dartx.href] = null;
      super.created();
    }
    get [dartx.type]() {
      return this.type;
    }
    set [dartx.type](value) {
      this.type = value;
    }
    get [dartx.href]() {
      return this.href;
    }
  }
  ScriptElement[dart.implements] = () => [UriReference];
  dart.defineNamedConstructor(ScriptElement, 'created');
  dart.setSignature(ScriptElement, {
    constructors: () => ({
      _: [ScriptElement, []],
      new: [ScriptElement, []],
      created: [ScriptElement, []]
    })
  });
  ScriptElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGScriptElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGScriptElement"))];
  dart.registerExtension(dart.global.SVGScriptElement, ScriptElement);
  class SetElement extends AnimationElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("set"), SetElement);
    }
    created() {
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('set')) && dart.is(SvgElement.tag('set'), SetElement);
    }
  }
  dart.defineNamedConstructor(SetElement, 'created');
  dart.setSignature(SetElement, {
    constructors: () => ({
      _: [SetElement, []],
      new: [SetElement, []],
      created: [SetElement, []]
    })
  });
  SetElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGSetElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGSetElement"))];
  dart.registerExtension(dart.global.SVGSetElement, SetElement);
  dart.defineExtensionNames([
    'gradientOffset'
  ]);
  class StopElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("stop"), StopElement);
    }
    created() {
      this[dartx.gradientOffset] = null;
      super.created();
    }
    get [dartx.gradientOffset]() {
      return this.offset;
    }
  }
  dart.defineNamedConstructor(StopElement, 'created');
  dart.setSignature(StopElement, {
    constructors: () => ({
      _: [StopElement, []],
      new: [StopElement, []],
      created: [StopElement, []]
    })
  });
  StopElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGStopElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGStopElement"))];
  dart.registerExtension(dart.global.SVGStopElement, StopElement);
  dart.defineExtensionNames([
    'length',
    'get',
    'set',
    'length',
    'first',
    'last',
    'single',
    'elementAt',
    'appendItem',
    'clear',
    'getItem',
    'initialize',
    'insertItemBefore',
    'removeItem',
    'replaceItem',
    'numberOfItems'
  ]);
  class StringList extends dart.mixin(_interceptors.Interceptor, collection.ListMixin$(core.String), html$.ImmutableListMixin$(core.String)) {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.length]() {
      return this.length;
    }
    get [dartx.numberOfItems]() {
      return this.numberOfItems;
    }
    [dartx.get](index) {
      if (index >>> 0 !== index || index >= this[dartx.length]) dart.throw(core.RangeError.index(index, this));
      return this[dartx.getItem](index);
    }
    [dartx.set](index, value) {
      dart.throw(new core.UnsupportedError("Cannot assign element of immutable List."));
      return value;
    }
    set [dartx.length](value) {
      dart.throw(new core.UnsupportedError("Cannot resize immutable List."));
    }
    get [dartx.first]() {
      if (dart.notNull(this[dartx.length]) > 0) {
        return this[0];
      }
      dart.throw(new core.StateError("No elements"));
    }
    get [dartx.last]() {
      let len = this[dartx.length];
      if (dart.notNull(len) > 0) {
        return this[dart.notNull(len) - 1];
      }
      dart.throw(new core.StateError("No elements"));
    }
    get [dartx.single]() {
      let len = this[dartx.length];
      if (len == 1) {
        return this[0];
      }
      if (len == 0) dart.throw(new core.StateError("No elements"));
      dart.throw(new core.StateError("More than one element"));
    }
    [dartx.elementAt](index) {
      return this[dartx.get](index);
    }
    [__setter__](index, value) {
      return this.__setter__(index, value);
    }
    [dartx.appendItem](item) {
      return this.appendItem(item);
    }
    [dartx.clear]() {
      return this.clear();
    }
    [dartx.getItem](index) {
      return this.getItem(index);
    }
    [dartx.initialize](item) {
      return this.initialize(item);
    }
    [dartx.insertItemBefore](item, index) {
      return this.insertItemBefore(item, index);
    }
    [dartx.removeItem](index) {
      return this.removeItem(index);
    }
    [dartx.replaceItem](item, index) {
      return this.replaceItem(item, index);
    }
  }
  StringList[dart.implements] = () => [core.List$(core.String)];
  dart.setSignature(StringList, {
    constructors: () => ({_: [StringList, []]}),
    methods: () => ({
      [dartx.get]: [core.String, [core.int]],
      [dartx.set]: [dart.void, [core.int, core.String]],
      [dartx.elementAt]: [core.String, [core.int]],
      [__setter__]: [dart.void, [core.int, core.String]],
      [dartx.appendItem]: [core.String, [core.String]],
      [dartx.getItem]: [core.String, [core.int]],
      [dartx.initialize]: [core.String, [core.String]],
      [dartx.insertItemBefore]: [core.String, [core.String, core.int]],
      [dartx.removeItem]: [core.String, [core.int]],
      [dartx.replaceItem]: [core.String, [core.String, core.int]]
    })
  });
  StringList[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGStringList')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGStringList"))];
  dart.registerExtension(dart.global.SVGStringList, StringList);
  dart.defineExtensionNames([
    'title',
    'title',
    'disabled',
    'media',
    'sheet',
    'type'
  ]);
  class StyleElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("style"), StyleElement);
    }
    created() {
      this[dartx.disabled] = null;
      this[dartx.media] = null;
      this[dartx.sheet] = null;
      this[dartx.type] = null;
      super.created();
    }
    get [dartx.disabled]() {
      return this.disabled;
    }
    set [dartx.disabled](value) {
      this.disabled = value;
    }
    get [dartx.media]() {
      return this.media;
    }
    set [dartx.media](value) {
      this.media = value;
    }
    get [dartx.sheet]() {
      return this.sheet;
    }
    get [dartx.title]() {
      return this.title;
    }
    set [dartx.title](value) {
      this.title = value;
    }
    get [dartx.type]() {
      return this.type;
    }
    set [dartx.type](value) {
      this.type = value;
    }
  }
  dart.defineNamedConstructor(StyleElement, 'created');
  dart.setSignature(StyleElement, {
    constructors: () => ({
      _: [StyleElement, []],
      new: [StyleElement, []],
      created: [StyleElement, []]
    })
  });
  StyleElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGStyleElement')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("SVGStyleElement"))];
  dart.registerExtension(dart.global.SVGStyleElement, StyleElement);
  const _element = Symbol('_element');
  class _AttributeClassSet extends html_common.CssClassSetImpl {
    _AttributeClassSet(element) {
      this[_element] = element;
    }
    readClasses() {
      let classname = this[_element][dartx.attributes][dartx.get]('class');
      let s = collection.LinkedHashSet$(core.String).new();
      if (classname == null) {
        return s;
      }
      for (let name of classname[dartx.split](' ')) {
        let trimmed = name[dartx.trim]();
        if (!dart.notNull(trimmed[dartx.isEmpty])) {
          s.add(trimmed);
        }
      }
      return s;
    }
    writeClasses(s) {
      this[_element][dartx.attributes][dartx.set]('class', s.join(' '));
    }
  }
  dart.setSignature(_AttributeClassSet, {
    constructors: () => ({_AttributeClassSet: [_AttributeClassSet, [html$.Element]]}),
    methods: () => ({
      readClasses: [core.Set$(core.String), []],
      writeClasses: [dart.void, [core.Set]]
    })
  });
  dart.defineExtensionNames([
    'animationsPaused',
    'checkEnclosure',
    'checkIntersection',
    'createSvgAngle',
    'createSvgLength',
    'createSvgMatrix',
    'createSvgNumber',
    'createSvgPoint',
    'createSvgRect',
    'createSvgTransform',
    'createSvgTransformFromMatrix',
    'deselectAll',
    'forceRedraw',
    'getCurrentTime',
    'getElementById',
    'getEnclosureList',
    'getIntersectionList',
    'pauseAnimations',
    'setCurrentTime',
    'suspendRedraw',
    'unpauseAnimations',
    'unsuspendRedraw',
    'unsuspendRedrawAll',
    'currentScale',
    'currentTranslate',
    'currentView',
    'height',
    'pixelUnitToMillimeterX',
    'pixelUnitToMillimeterY',
    'screenPixelToMillimeterX',
    'screenPixelToMillimeterY',
    'useCurrentView',
    'viewport',
    'width',
    'x',
    'y',
    'preserveAspectRatio',
    'viewBox',
    'zoomAndPan'
  ]);
  class SvgSvgElement extends GraphicsElement {
    static new() {
      let el = SvgElement.tag("svg");
      el[dartx.attributes][dartx.set]('version', "1.1");
      return dart.as(el, SvgSvgElement);
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      this[dartx.currentScale] = null;
      this[dartx.currentTranslate] = null;
      this[dartx.currentView] = null;
      this[dartx.height] = null;
      this[dartx.pixelUnitToMillimeterX] = null;
      this[dartx.pixelUnitToMillimeterY] = null;
      this[dartx.screenPixelToMillimeterX] = null;
      this[dartx.screenPixelToMillimeterY] = null;
      this[dartx.useCurrentView] = null;
      this[dartx.viewport] = null;
      this[dartx.width] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      this[dartx.preserveAspectRatio] = null;
      this[dartx.viewBox] = null;
      this[dartx.zoomAndPan] = null;
      super.created();
    }
    get [dartx.currentScale]() {
      return this.currentScale;
    }
    set [dartx.currentScale](value) {
      this.currentScale = value;
    }
    get [dartx.currentTranslate]() {
      return this.currentTranslate;
    }
    get [dartx.currentView]() {
      return this.currentView;
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.pixelUnitToMillimeterX]() {
      return this.pixelUnitToMillimeterX;
    }
    get [dartx.pixelUnitToMillimeterY]() {
      return this.pixelUnitToMillimeterY;
    }
    get [dartx.screenPixelToMillimeterX]() {
      return this.screenPixelToMillimeterX;
    }
    get [dartx.screenPixelToMillimeterY]() {
      return this.screenPixelToMillimeterY;
    }
    get [dartx.useCurrentView]() {
      return this.useCurrentView;
    }
    get [dartx.viewport]() {
      return this.viewport;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
    [dartx.animationsPaused]() {
      return this.animationsPaused();
    }
    [dartx.checkEnclosure](element, rect) {
      return this.checkEnclosure(element, rect);
    }
    [dartx.checkIntersection](element, rect) {
      return this.checkIntersection(element, rect);
    }
    [dartx.createSvgAngle]() {
      return this.createSVGAngle();
    }
    [dartx.createSvgLength]() {
      return this.createSVGLength();
    }
    [dartx.createSvgMatrix]() {
      return this.createSVGMatrix();
    }
    [dartx.createSvgNumber]() {
      return this.createSVGNumber();
    }
    [dartx.createSvgPoint]() {
      return this.createSVGPoint();
    }
    [dartx.createSvgRect]() {
      return this.createSVGRect();
    }
    [dartx.createSvgTransform]() {
      return this.createSVGTransform();
    }
    [dartx.createSvgTransformFromMatrix](matrix) {
      return this.createSVGTransformFromMatrix(matrix);
    }
    [dartx.deselectAll]() {
      return this.deselectAll();
    }
    [dartx.forceRedraw]() {
      return this.forceRedraw();
    }
    [dartx.getCurrentTime]() {
      return this.getCurrentTime();
    }
    [dartx.getElementById](elementId) {
      return this.getElementById(elementId);
    }
    [dartx.getEnclosureList](rect, referenceElement) {
      return this.getEnclosureList(rect, referenceElement);
    }
    [dartx.getIntersectionList](rect, referenceElement) {
      return this.getIntersectionList(rect, referenceElement);
    }
    [dartx.pauseAnimations]() {
      return this.pauseAnimations();
    }
    [dartx.setCurrentTime](seconds) {
      return this.setCurrentTime(seconds);
    }
    [dartx.suspendRedraw](maxWaitMilliseconds) {
      return this.suspendRedraw(maxWaitMilliseconds);
    }
    [dartx.unpauseAnimations]() {
      return this.unpauseAnimations();
    }
    [dartx.unsuspendRedraw](suspendHandleId) {
      return this.unsuspendRedraw(suspendHandleId);
    }
    [dartx.unsuspendRedrawAll]() {
      return this.unsuspendRedrawAll();
    }
    get [dartx.preserveAspectRatio]() {
      return this.preserveAspectRatio;
    }
    get [dartx.viewBox]() {
      return this.viewBox;
    }
    get [dartx.zoomAndPan]() {
      return this.zoomAndPan;
    }
    set [dartx.zoomAndPan](value) {
      this.zoomAndPan = value;
    }
  }
  SvgSvgElement[dart.implements] = () => [FitToViewBox, ZoomAndPan];
  dart.defineNamedConstructor(SvgSvgElement, 'created');
  dart.setSignature(SvgSvgElement, {
    constructors: () => ({
      new: [SvgSvgElement, []],
      _: [SvgSvgElement, []],
      created: [SvgSvgElement, []]
    }),
    methods: () => ({
      [dartx.animationsPaused]: [core.bool, []],
      [dartx.checkEnclosure]: [core.bool, [SvgElement, Rect]],
      [dartx.checkIntersection]: [core.bool, [SvgElement, Rect]],
      [dartx.createSvgAngle]: [Angle, []],
      [dartx.createSvgLength]: [Length, []],
      [dartx.createSvgMatrix]: [Matrix, []],
      [dartx.createSvgNumber]: [Number, []],
      [dartx.createSvgPoint]: [Point, []],
      [dartx.createSvgRect]: [Rect, []],
      [dartx.createSvgTransform]: [Transform, []],
      [dartx.createSvgTransformFromMatrix]: [Transform, [Matrix]],
      [dartx.deselectAll]: [dart.void, []],
      [dartx.forceRedraw]: [dart.void, []],
      [dartx.getCurrentTime]: [core.double, []],
      [dartx.getElementById]: [html$.Element, [core.String]],
      [dartx.getEnclosureList]: [core.List$(html$.Node), [Rect, SvgElement]],
      [dartx.getIntersectionList]: [core.List$(html$.Node), [Rect, SvgElement]],
      [dartx.pauseAnimations]: [dart.void, []],
      [dartx.setCurrentTime]: [dart.void, [core.num]],
      [dartx.suspendRedraw]: [core.int, [core.int]],
      [dartx.unpauseAnimations]: [dart.void, []],
      [dartx.unsuspendRedraw]: [dart.void, [core.int]],
      [dartx.unsuspendRedrawAll]: [dart.void, []]
    })
  });
  SvgSvgElement[dart.metadata] = () => [dart.const(new _metadata.DomName('SVGSVGElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGSVGElement"))];
  dart.registerExtension(dart.global.SVGSVGElement, SvgSvgElement);
  class SwitchElement extends GraphicsElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("switch"), SwitchElement);
    }
    created() {
      super.created();
    }
  }
  dart.defineNamedConstructor(SwitchElement, 'created');
  dart.setSignature(SwitchElement, {
    constructors: () => ({
      _: [SwitchElement, []],
      new: [SwitchElement, []],
      created: [SwitchElement, []]
    })
  });
  SwitchElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGSwitchElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGSwitchElement"))];
  dart.registerExtension(dart.global.SVGSwitchElement, SwitchElement);
  dart.defineExtensionNames([
    'preserveAspectRatio',
    'viewBox'
  ]);
  class SymbolElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("symbol"), SymbolElement);
    }
    created() {
      this[dartx.preserveAspectRatio] = null;
      this[dartx.viewBox] = null;
      super.created();
    }
    get [dartx.preserveAspectRatio]() {
      return this.preserveAspectRatio;
    }
    get [dartx.viewBox]() {
      return this.viewBox;
    }
  }
  SymbolElement[dart.implements] = () => [FitToViewBox];
  dart.defineNamedConstructor(SymbolElement, 'created');
  dart.setSignature(SymbolElement, {
    constructors: () => ({
      _: [SymbolElement, []],
      new: [SymbolElement, []],
      created: [SymbolElement, []]
    })
  });
  SymbolElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGSymbolElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGSymbolElement"))];
  dart.registerExtension(dart.global.SVGSymbolElement, SymbolElement);
  class TSpanElement extends TextPositioningElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("tspan"), TSpanElement);
    }
    created() {
      super.created();
    }
  }
  dart.defineNamedConstructor(TSpanElement, 'created');
  dart.setSignature(TSpanElement, {
    constructors: () => ({
      _: [TSpanElement, []],
      new: [TSpanElement, []],
      created: [TSpanElement, []]
    })
  });
  TSpanElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGTSpanElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGTSpanElement"))];
  dart.registerExtension(dart.global.SVGTSpanElement, TSpanElement);
  dart.defineExtensionNames([
    'requiredExtensions',
    'requiredFeatures',
    'systemLanguage'
  ]);
  class Tests extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.requiredExtensions]() {
      return this.requiredExtensions;
    }
    get [dartx.requiredFeatures]() {
      return this.requiredFeatures;
    }
    get [dartx.systemLanguage]() {
      return this.systemLanguage;
    }
  }
  dart.setSignature(Tests, {
    constructors: () => ({_: [Tests, []]})
  });
  Tests[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGTests')), dart.const(new _metadata.Unstable())];
  class TextElement extends TextPositioningElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("text"), TextElement);
    }
    created() {
      super.created();
    }
  }
  dart.defineNamedConstructor(TextElement, 'created');
  dart.setSignature(TextElement, {
    constructors: () => ({
      _: [TextElement, []],
      new: [TextElement, []],
      created: [TextElement, []]
    })
  });
  TextElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGTextElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGTextElement"))];
  dart.registerExtension(dart.global.SVGTextElement, TextElement);
  dart.defineExtensionNames([
    'method',
    'spacing',
    'startOffset',
    'href'
  ]);
  class TextPathElement extends TextContentElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      this[dartx.method] = null;
      this[dartx.spacing] = null;
      this[dartx.startOffset] = null;
      this[dartx.href] = null;
      super.created();
    }
    get [dartx.method]() {
      return this.method;
    }
    get [dartx.spacing]() {
      return this.spacing;
    }
    get [dartx.startOffset]() {
      return this.startOffset;
    }
    get [dartx.href]() {
      return this.href;
    }
  }
  TextPathElement[dart.implements] = () => [UriReference];
  dart.defineNamedConstructor(TextPathElement, 'created');
  dart.setSignature(TextPathElement, {
    constructors: () => ({
      _: [TextPathElement, []],
      created: [TextPathElement, []]
    })
  });
  TextPathElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGTextPathElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGTextPathElement"))];
  TextPathElement.TEXTPATH_METHODTYPE_ALIGN = 1;
  TextPathElement.TEXTPATH_METHODTYPE_STRETCH = 2;
  TextPathElement.TEXTPATH_METHODTYPE_UNKNOWN = 0;
  TextPathElement.TEXTPATH_SPACINGTYPE_AUTO = 1;
  TextPathElement.TEXTPATH_SPACINGTYPE_EXACT = 2;
  TextPathElement.TEXTPATH_SPACINGTYPE_UNKNOWN = 0;
  dart.registerExtension(dart.global.SVGTextPathElement, TextPathElement);
  class TitleElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("title"), TitleElement);
    }
    created() {
      super.created();
    }
  }
  dart.defineNamedConstructor(TitleElement, 'created');
  dart.setSignature(TitleElement, {
    constructors: () => ({
      _: [TitleElement, []],
      new: [TitleElement, []],
      created: [TitleElement, []]
    })
  });
  TitleElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGTitleElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGTitleElement"))];
  dart.registerExtension(dart.global.SVGTitleElement, TitleElement);
  dart.defineExtensionNames([
    'setMatrix',
    'setRotate',
    'setScale',
    'setSkewX',
    'setSkewY',
    'setTranslate',
    'angle',
    'matrix',
    'type'
  ]);
  class Transform extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.angle]() {
      return this.angle;
    }
    get [dartx.matrix]() {
      return this.matrix;
    }
    get [dartx.type]() {
      return this.type;
    }
    [dartx.setMatrix](matrix) {
      return this.setMatrix(matrix);
    }
    [dartx.setRotate](angle, cx, cy) {
      return this.setRotate(angle, cx, cy);
    }
    [dartx.setScale](sx, sy) {
      return this.setScale(sx, sy);
    }
    [dartx.setSkewX](angle) {
      return this.setSkewX(angle);
    }
    [dartx.setSkewY](angle) {
      return this.setSkewY(angle);
    }
    [dartx.setTranslate](tx, ty) {
      return this.setTranslate(tx, ty);
    }
  }
  dart.setSignature(Transform, {
    constructors: () => ({_: [Transform, []]}),
    methods: () => ({
      [dartx.setMatrix]: [dart.void, [Matrix]],
      [dartx.setRotate]: [dart.void, [core.num, core.num, core.num]],
      [dartx.setScale]: [dart.void, [core.num, core.num]],
      [dartx.setSkewX]: [dart.void, [core.num]],
      [dartx.setSkewY]: [dart.void, [core.num]],
      [dartx.setTranslate]: [dart.void, [core.num, core.num]]
    })
  });
  Transform[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGTransform')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGTransform"))];
  Transform.SVG_TRANSFORM_MATRIX = 1;
  Transform.SVG_TRANSFORM_ROTATE = 4;
  Transform.SVG_TRANSFORM_SCALE = 3;
  Transform.SVG_TRANSFORM_SKEWX = 5;
  Transform.SVG_TRANSFORM_SKEWY = 6;
  Transform.SVG_TRANSFORM_TRANSLATE = 2;
  Transform.SVG_TRANSFORM_UNKNOWN = 0;
  dart.registerExtension(dart.global.SVGTransform, Transform);
  dart.defineExtensionNames([
    'length',
    'get',
    'set',
    'length',
    'first',
    'last',
    'single',
    'elementAt',
    'appendItem',
    'clear',
    'consolidate',
    'createSvgTransformFromMatrix',
    'getItem',
    'initialize',
    'insertItemBefore',
    'removeItem',
    'replaceItem',
    'numberOfItems'
  ]);
  class TransformList extends dart.mixin(_interceptors.Interceptor, collection.ListMixin$(Transform), html$.ImmutableListMixin$(Transform)) {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.length]() {
      return this.length;
    }
    get [dartx.numberOfItems]() {
      return this.numberOfItems;
    }
    [dartx.get](index) {
      if (index >>> 0 !== index || index >= this[dartx.length]) dart.throw(core.RangeError.index(index, this));
      return this[dartx.getItem](index);
    }
    [dartx.set](index, value) {
      dart.throw(new core.UnsupportedError("Cannot assign element of immutable List."));
      return value;
    }
    set [dartx.length](value) {
      dart.throw(new core.UnsupportedError("Cannot resize immutable List."));
    }
    get [dartx.first]() {
      if (dart.notNull(this[dartx.length]) > 0) {
        return dart.as(this[0], Transform);
      }
      dart.throw(new core.StateError("No elements"));
    }
    get [dartx.last]() {
      let len = this[dartx.length];
      if (dart.notNull(len) > 0) {
        return dart.as(this[dart.notNull(len) - 1], Transform);
      }
      dart.throw(new core.StateError("No elements"));
    }
    get [dartx.single]() {
      let len = this[dartx.length];
      if (len == 1) {
        return dart.as(this[0], Transform);
      }
      if (len == 0) dart.throw(new core.StateError("No elements"));
      dart.throw(new core.StateError("More than one element"));
    }
    [dartx.elementAt](index) {
      return this[dartx.get](index);
    }
    [__setter__](index, value) {
      return this.__setter__(index, value);
    }
    [dartx.appendItem](item) {
      return this.appendItem(item);
    }
    [dartx.clear]() {
      return this.clear();
    }
    [dartx.consolidate]() {
      return this.consolidate();
    }
    [dartx.createSvgTransformFromMatrix](matrix) {
      return this.createSVGTransformFromMatrix(matrix);
    }
    [dartx.getItem](index) {
      return this.getItem(index);
    }
    [dartx.initialize](item) {
      return this.initialize(item);
    }
    [dartx.insertItemBefore](item, index) {
      return this.insertItemBefore(item, index);
    }
    [dartx.removeItem](index) {
      return this.removeItem(index);
    }
    [dartx.replaceItem](item, index) {
      return this.replaceItem(item, index);
    }
  }
  TransformList[dart.implements] = () => [core.List$(Transform)];
  dart.setSignature(TransformList, {
    constructors: () => ({_: [TransformList, []]}),
    methods: () => ({
      [dartx.get]: [Transform, [core.int]],
      [dartx.set]: [dart.void, [core.int, Transform]],
      [dartx.elementAt]: [Transform, [core.int]],
      [__setter__]: [dart.void, [core.int, Transform]],
      [dartx.appendItem]: [Transform, [Transform]],
      [dartx.consolidate]: [Transform, []],
      [dartx.createSvgTransformFromMatrix]: [Transform, [Matrix]],
      [dartx.getItem]: [Transform, [core.int]],
      [dartx.initialize]: [Transform, [Transform]],
      [dartx.insertItemBefore]: [Transform, [Transform, core.int]],
      [dartx.removeItem]: [Transform, [core.int]],
      [dartx.replaceItem]: [Transform, [Transform, core.int]]
    })
  });
  TransformList[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGTransformList')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGTransformList"))];
  dart.registerExtension(dart.global.SVGTransformList, TransformList);
  class UnitTypes extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(UnitTypes, {
    constructors: () => ({_: [UnitTypes, []]})
  });
  UnitTypes[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGUnitTypes')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGUnitTypes"))];
  UnitTypes.SVG_UNIT_TYPE_OBJECTBOUNDINGBOX = 2;
  UnitTypes.SVG_UNIT_TYPE_UNKNOWN = 0;
  UnitTypes.SVG_UNIT_TYPE_USERSPACEONUSE = 1;
  dart.registerExtension(dart.global.SVGUnitTypes, UnitTypes);
  dart.defineExtensionNames([
    'href'
  ]);
  class UriReference extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.href]() {
      return this.href;
    }
  }
  dart.setSignature(UriReference, {
    constructors: () => ({_: [UriReference, []]})
  });
  UriReference[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGURIReference')), dart.const(new _metadata.Unstable())];
  dart.defineExtensionNames([
    'height',
    'width',
    'x',
    'y',
    'href'
  ]);
  class UseElement extends GraphicsElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("use"), UseElement);
    }
    created() {
      this[dartx.height] = null;
      this[dartx.width] = null;
      this[dartx.x] = null;
      this[dartx.y] = null;
      this[dartx.href] = null;
      super.created();
    }
    get [dartx.height]() {
      return this.height;
    }
    get [dartx.width]() {
      return this.width;
    }
    get [dartx.x]() {
      return this.x;
    }
    get [dartx.y]() {
      return this.y;
    }
    get [dartx.href]() {
      return this.href;
    }
  }
  UseElement[dart.implements] = () => [UriReference];
  dart.defineNamedConstructor(UseElement, 'created');
  dart.setSignature(UseElement, {
    constructors: () => ({
      _: [UseElement, []],
      new: [UseElement, []],
      created: [UseElement, []]
    })
  });
  UseElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGUseElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGUseElement"))];
  dart.registerExtension(dart.global.SVGUseElement, UseElement);
  dart.defineExtensionNames([
    'viewTarget',
    'preserveAspectRatio',
    'viewBox',
    'zoomAndPan'
  ]);
  class ViewElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("view"), ViewElement);
    }
    created() {
      this[dartx.viewTarget] = null;
      this[dartx.preserveAspectRatio] = null;
      this[dartx.viewBox] = null;
      this[dartx.zoomAndPan] = null;
      super.created();
    }
    get [dartx.viewTarget]() {
      return this.viewTarget;
    }
    get [dartx.preserveAspectRatio]() {
      return this.preserveAspectRatio;
    }
    get [dartx.viewBox]() {
      return this.viewBox;
    }
    get [dartx.zoomAndPan]() {
      return this.zoomAndPan;
    }
    set [dartx.zoomAndPan](value) {
      this.zoomAndPan = value;
    }
  }
  ViewElement[dart.implements] = () => [FitToViewBox, ZoomAndPan];
  dart.defineNamedConstructor(ViewElement, 'created');
  dart.setSignature(ViewElement, {
    constructors: () => ({
      _: [ViewElement, []],
      new: [ViewElement, []],
      created: [ViewElement, []]
    })
  });
  ViewElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGViewElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGViewElement"))];
  dart.registerExtension(dart.global.SVGViewElement, ViewElement);
  dart.defineExtensionNames([
    'preserveAspectRatioString',
    'transform',
    'transformString',
    'viewBoxString',
    'viewTarget',
    'viewTargetString',
    'preserveAspectRatio',
    'viewBox',
    'zoomAndPan'
  ]);
  class ViewSpec extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.preserveAspectRatioString]() {
      return this.preserveAspectRatioString;
    }
    get [dartx.transform]() {
      return this.transform;
    }
    get [dartx.transformString]() {
      return this.transformString;
    }
    get [dartx.viewBoxString]() {
      return this.viewBoxString;
    }
    get [dartx.viewTarget]() {
      return this.viewTarget;
    }
    get [dartx.viewTargetString]() {
      return this.viewTargetString;
    }
    get [dartx.preserveAspectRatio]() {
      return this.preserveAspectRatio;
    }
    get [dartx.viewBox]() {
      return this.viewBox;
    }
    get [dartx.zoomAndPan]() {
      return this.zoomAndPan;
    }
    set [dartx.zoomAndPan](value) {
      this.zoomAndPan = value;
    }
  }
  ViewSpec[dart.implements] = () => [FitToViewBox, ZoomAndPan];
  dart.setSignature(ViewSpec, {
    constructors: () => ({_: [ViewSpec, []]})
  });
  ViewSpec[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGViewSpec')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGViewSpec"))];
  dart.registerExtension(dart.global.SVGViewSpec, ViewSpec);
  dart.defineExtensionNames([
    'zoomAndPan'
  ]);
  class ZoomAndPan extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.zoomAndPan]() {
      return this.zoomAndPan;
    }
    set [dartx.zoomAndPan](value) {
      this.zoomAndPan = value;
    }
  }
  dart.setSignature(ZoomAndPan, {
    constructors: () => ({_: [ZoomAndPan, []]})
  });
  ZoomAndPan[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGZoomAndPan')), dart.const(new _metadata.Unstable())];
  ZoomAndPan.SVG_ZOOMANDPAN_DISABLE = 1;
  ZoomAndPan.SVG_ZOOMANDPAN_MAGNIFY = 2;
  ZoomAndPan.SVG_ZOOMANDPAN_UNKNOWN = 0;
  dart.defineExtensionNames([
    'newScale',
    'newTranslate',
    'previousScale',
    'previousTranslate',
    'zoomRectScreen'
  ]);
  class ZoomEvent extends html$.UIEvent {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.newScale]() {
      return this.newScale;
    }
    get [dartx.newTranslate]() {
      return this.newTranslate;
    }
    get [dartx.previousScale]() {
      return this.previousScale;
    }
    get [dartx.previousTranslate]() {
      return this.previousTranslate;
    }
    get [dartx.zoomRectScreen]() {
      return this.zoomRectScreen;
    }
  }
  dart.setSignature(ZoomEvent, {
    constructors: () => ({_: [ZoomEvent, []]})
  });
  ZoomEvent[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGZoomEvent')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGZoomEvent"))];
  dart.registerExtension(dart.global.SVGZoomEvent, ZoomEvent);
  class _SVGAltGlyphDefElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      super.created();
    }
  }
  dart.defineNamedConstructor(_SVGAltGlyphDefElement, 'created');
  dart.setSignature(_SVGAltGlyphDefElement, {
    constructors: () => ({
      _: [_SVGAltGlyphDefElement, []],
      created: [_SVGAltGlyphDefElement, []]
    })
  });
  _SVGAltGlyphDefElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGAltGlyphDefElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGAltGlyphDefElement"))];
  dart.registerExtension(dart.global.SVGAltGlyphDefElement, _SVGAltGlyphDefElement);
  class _SVGAltGlyphItemElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      super.created();
    }
  }
  dart.defineNamedConstructor(_SVGAltGlyphItemElement, 'created');
  dart.setSignature(_SVGAltGlyphItemElement, {
    constructors: () => ({
      _: [_SVGAltGlyphItemElement, []],
      created: [_SVGAltGlyphItemElement, []]
    })
  });
  _SVGAltGlyphItemElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGAltGlyphItemElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGAltGlyphItemElement"))];
  dart.registerExtension(dart.global.SVGAltGlyphItemElement, _SVGAltGlyphItemElement);
  class _SVGCursorElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("cursor"), _SVGCursorElement);
    }
    created() {
      super.created();
    }
    static get supported() {
      return dart.notNull(SvgElement.isTagSupported('cursor')) && dart.is(SvgElement.tag('cursor'), _SVGCursorElement);
    }
  }
  _SVGCursorElement[dart.implements] = () => [UriReference, Tests];
  dart.defineNamedConstructor(_SVGCursorElement, 'created');
  dart.setSignature(_SVGCursorElement, {
    constructors: () => ({
      _: [_SVGCursorElement, []],
      new: [_SVGCursorElement, []],
      created: [_SVGCursorElement, []]
    })
  });
  _SVGCursorElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGCursorElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGCursorElement"))];
  dart.registerExtension(dart.global.SVGCursorElement, _SVGCursorElement);
  class _SVGFEDropShadowElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      super.created();
    }
  }
  _SVGFEDropShadowElement[dart.implements] = () => [FilterPrimitiveStandardAttributes];
  dart.defineNamedConstructor(_SVGFEDropShadowElement, 'created');
  dart.setSignature(_SVGFEDropShadowElement, {
    constructors: () => ({
      _: [_SVGFEDropShadowElement, []],
      created: [_SVGFEDropShadowElement, []]
    })
  });
  _SVGFEDropShadowElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFEDropShadowElement')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("SVGFEDropShadowElement"))];
  dart.registerExtension(dart.global.SVGFEDropShadowElement, _SVGFEDropShadowElement);
  class _SVGFontElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      super.created();
    }
  }
  dart.defineNamedConstructor(_SVGFontElement, 'created');
  dart.setSignature(_SVGFontElement, {
    constructors: () => ({
      _: [_SVGFontElement, []],
      created: [_SVGFontElement, []]
    })
  });
  _SVGFontElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFontElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFontElement"))];
  dart.registerExtension(dart.global.SVGFontElement, _SVGFontElement);
  class _SVGFontFaceElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      super.created();
    }
  }
  dart.defineNamedConstructor(_SVGFontFaceElement, 'created');
  dart.setSignature(_SVGFontFaceElement, {
    constructors: () => ({
      _: [_SVGFontFaceElement, []],
      created: [_SVGFontFaceElement, []]
    })
  });
  _SVGFontFaceElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFontFaceElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFontFaceElement"))];
  dart.registerExtension(dart.global.SVGFontFaceElement, _SVGFontFaceElement);
  class _SVGFontFaceFormatElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      super.created();
    }
  }
  dart.defineNamedConstructor(_SVGFontFaceFormatElement, 'created');
  dart.setSignature(_SVGFontFaceFormatElement, {
    constructors: () => ({
      _: [_SVGFontFaceFormatElement, []],
      created: [_SVGFontFaceFormatElement, []]
    })
  });
  _SVGFontFaceFormatElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFontFaceFormatElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFontFaceFormatElement"))];
  dart.registerExtension(dart.global.SVGFontFaceFormatElement, _SVGFontFaceFormatElement);
  class _SVGFontFaceNameElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      super.created();
    }
  }
  dart.defineNamedConstructor(_SVGFontFaceNameElement, 'created');
  dart.setSignature(_SVGFontFaceNameElement, {
    constructors: () => ({
      _: [_SVGFontFaceNameElement, []],
      created: [_SVGFontFaceNameElement, []]
    })
  });
  _SVGFontFaceNameElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFontFaceNameElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFontFaceNameElement"))];
  dart.registerExtension(dart.global.SVGFontFaceNameElement, _SVGFontFaceNameElement);
  class _SVGFontFaceSrcElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      super.created();
    }
  }
  dart.defineNamedConstructor(_SVGFontFaceSrcElement, 'created');
  dart.setSignature(_SVGFontFaceSrcElement, {
    constructors: () => ({
      _: [_SVGFontFaceSrcElement, []],
      created: [_SVGFontFaceSrcElement, []]
    })
  });
  _SVGFontFaceSrcElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFontFaceSrcElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFontFaceSrcElement"))];
  dart.registerExtension(dart.global.SVGFontFaceSrcElement, _SVGFontFaceSrcElement);
  class _SVGFontFaceUriElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      super.created();
    }
  }
  dart.defineNamedConstructor(_SVGFontFaceUriElement, 'created');
  dart.setSignature(_SVGFontFaceUriElement, {
    constructors: () => ({
      _: [_SVGFontFaceUriElement, []],
      created: [_SVGFontFaceUriElement, []]
    })
  });
  _SVGFontFaceUriElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGFontFaceUriElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGFontFaceUriElement"))];
  dart.registerExtension(dart.global.SVGFontFaceUriElement, _SVGFontFaceUriElement);
  class _SVGGlyphElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("glyph"), _SVGGlyphElement);
    }
    created() {
      super.created();
    }
  }
  dart.defineNamedConstructor(_SVGGlyphElement, 'created');
  dart.setSignature(_SVGGlyphElement, {
    constructors: () => ({
      _: [_SVGGlyphElement, []],
      new: [_SVGGlyphElement, []],
      created: [_SVGGlyphElement, []]
    })
  });
  _SVGGlyphElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGGlyphElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGGlyphElement"))];
  dart.registerExtension(dart.global.SVGGlyphElement, _SVGGlyphElement);
  class _SVGGlyphRefElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      super.created();
    }
  }
  _SVGGlyphRefElement[dart.implements] = () => [UriReference];
  dart.defineNamedConstructor(_SVGGlyphRefElement, 'created');
  dart.setSignature(_SVGGlyphRefElement, {
    constructors: () => ({
      _: [_SVGGlyphRefElement, []],
      created: [_SVGGlyphRefElement, []]
    })
  });
  _SVGGlyphRefElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGGlyphRefElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGGlyphRefElement"))];
  dart.registerExtension(dart.global.SVGGlyphRefElement, _SVGGlyphRefElement);
  class _SVGHKernElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("hkern"), _SVGHKernElement);
    }
    created() {
      super.created();
    }
  }
  dart.defineNamedConstructor(_SVGHKernElement, 'created');
  dart.setSignature(_SVGHKernElement, {
    constructors: () => ({
      _: [_SVGHKernElement, []],
      new: [_SVGHKernElement, []],
      created: [_SVGHKernElement, []]
    })
  });
  _SVGHKernElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGHKernElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGHKernElement"))];
  dart.registerExtension(dart.global.SVGHKernElement, _SVGHKernElement);
  class _SVGMPathElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("mpath"), _SVGMPathElement);
    }
    created() {
      super.created();
    }
  }
  _SVGMPathElement[dart.implements] = () => [UriReference];
  dart.defineNamedConstructor(_SVGMPathElement, 'created');
  dart.setSignature(_SVGMPathElement, {
    constructors: () => ({
      _: [_SVGMPathElement, []],
      new: [_SVGMPathElement, []],
      created: [_SVGMPathElement, []]
    })
  });
  _SVGMPathElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGMPathElement')), dart.const(new _js_helper.Native("SVGMPathElement"))];
  dart.registerExtension(dart.global.SVGMPathElement, _SVGMPathElement);
  class _SVGMissingGlyphElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      super.created();
    }
  }
  dart.defineNamedConstructor(_SVGMissingGlyphElement, 'created');
  dart.setSignature(_SVGMissingGlyphElement, {
    constructors: () => ({
      _: [_SVGMissingGlyphElement, []],
      created: [_SVGMissingGlyphElement, []]
    })
  });
  _SVGMissingGlyphElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGMissingGlyphElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGMissingGlyphElement"))];
  dart.registerExtension(dart.global.SVGMissingGlyphElement, _SVGMissingGlyphElement);
  class _SVGVKernElement extends SvgElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(_SvgElementFactoryProvider.createSvgElement_tag("vkern"), _SVGVKernElement);
    }
    created() {
      super.created();
    }
  }
  dart.defineNamedConstructor(_SVGVKernElement, 'created');
  dart.setSignature(_SVGVKernElement, {
    constructors: () => ({
      _: [_SVGVKernElement, []],
      new: [_SVGVKernElement, []],
      created: [_SVGVKernElement, []]
    })
  });
  _SVGVKernElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SVGVKernElement')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("SVGVKernElement"))];
  dart.registerExtension(dart.global.SVGVKernElement, _SVGVKernElement);
  // Exports:
  exports.SvgElement = SvgElement;
  exports.GraphicsElement = GraphicsElement;
  exports.AElement = AElement;
  exports.TextContentElement = TextContentElement;
  exports.TextPositioningElement = TextPositioningElement;
  exports.AltGlyphElement = AltGlyphElement;
  exports.Angle = Angle;
  exports.AnimationElement = AnimationElement;
  exports.AnimateElement = AnimateElement;
  exports.AnimateMotionElement = AnimateMotionElement;
  exports.AnimateTransformElement = AnimateTransformElement;
  exports.AnimatedAngle = AnimatedAngle;
  exports.AnimatedBoolean = AnimatedBoolean;
  exports.AnimatedEnumeration = AnimatedEnumeration;
  exports.AnimatedInteger = AnimatedInteger;
  exports.AnimatedLength = AnimatedLength;
  exports.AnimatedLengthList = AnimatedLengthList;
  exports.AnimatedNumber = AnimatedNumber;
  exports.AnimatedNumberList = AnimatedNumberList;
  exports.AnimatedPreserveAspectRatio = AnimatedPreserveAspectRatio;
  exports.AnimatedRect = AnimatedRect;
  exports.AnimatedString = AnimatedString;
  exports.AnimatedTransformList = AnimatedTransformList;
  exports.GeometryElement = GeometryElement;
  exports.CircleElement = CircleElement;
  exports.ClipPathElement = ClipPathElement;
  exports.DefsElement = DefsElement;
  exports.DescElement = DescElement;
  exports.DiscardElement = DiscardElement;
  exports.EllipseElement = EllipseElement;
  exports.FEBlendElement = FEBlendElement;
  exports.FEColorMatrixElement = FEColorMatrixElement;
  exports.FEComponentTransferElement = FEComponentTransferElement;
  exports.FECompositeElement = FECompositeElement;
  exports.FEConvolveMatrixElement = FEConvolveMatrixElement;
  exports.FEDiffuseLightingElement = FEDiffuseLightingElement;
  exports.FEDisplacementMapElement = FEDisplacementMapElement;
  exports.FEDistantLightElement = FEDistantLightElement;
  exports.FEFloodElement = FEFloodElement;
  exports.FEFuncAElement = FEFuncAElement;
  exports.FEFuncBElement = FEFuncBElement;
  exports.FEFuncGElement = FEFuncGElement;
  exports.FEFuncRElement = FEFuncRElement;
  exports.FEGaussianBlurElement = FEGaussianBlurElement;
  exports.FEImageElement = FEImageElement;
  exports.FEMergeElement = FEMergeElement;
  exports.FEMergeNodeElement = FEMergeNodeElement;
  exports.FEMorphologyElement = FEMorphologyElement;
  exports.FEOffsetElement = FEOffsetElement;
  exports.FEPointLightElement = FEPointLightElement;
  exports.FESpecularLightingElement = FESpecularLightingElement;
  exports.FESpotLightElement = FESpotLightElement;
  exports.FETileElement = FETileElement;
  exports.FETurbulenceElement = FETurbulenceElement;
  exports.FilterElement = FilterElement;
  exports.FilterPrimitiveStandardAttributes = FilterPrimitiveStandardAttributes;
  exports.FitToViewBox = FitToViewBox;
  exports.ForeignObjectElement = ForeignObjectElement;
  exports.GElement = GElement;
  exports.ImageElement = ImageElement;
  exports.Length = Length;
  exports.LengthList = LengthList;
  exports.LineElement = LineElement;
  exports.LinearGradientElement = LinearGradientElement;
  exports.MarkerElement = MarkerElement;
  exports.MaskElement = MaskElement;
  exports.Matrix = Matrix;
  exports.MetadataElement = MetadataElement;
  exports.Number = Number;
  exports.NumberList = NumberList;
  exports.PathElement = PathElement;
  exports.PathSeg = PathSeg;
  exports.PathSegArcAbs = PathSegArcAbs;
  exports.PathSegArcRel = PathSegArcRel;
  exports.PathSegClosePath = PathSegClosePath;
  exports.PathSegCurvetoCubicAbs = PathSegCurvetoCubicAbs;
  exports.PathSegCurvetoCubicRel = PathSegCurvetoCubicRel;
  exports.PathSegCurvetoCubicSmoothAbs = PathSegCurvetoCubicSmoothAbs;
  exports.PathSegCurvetoCubicSmoothRel = PathSegCurvetoCubicSmoothRel;
  exports.PathSegCurvetoQuadraticAbs = PathSegCurvetoQuadraticAbs;
  exports.PathSegCurvetoQuadraticRel = PathSegCurvetoQuadraticRel;
  exports.PathSegCurvetoQuadraticSmoothAbs = PathSegCurvetoQuadraticSmoothAbs;
  exports.PathSegCurvetoQuadraticSmoothRel = PathSegCurvetoQuadraticSmoothRel;
  exports.PathSegLinetoAbs = PathSegLinetoAbs;
  exports.PathSegLinetoHorizontalAbs = PathSegLinetoHorizontalAbs;
  exports.PathSegLinetoHorizontalRel = PathSegLinetoHorizontalRel;
  exports.PathSegLinetoRel = PathSegLinetoRel;
  exports.PathSegLinetoVerticalAbs = PathSegLinetoVerticalAbs;
  exports.PathSegLinetoVerticalRel = PathSegLinetoVerticalRel;
  exports.PathSegList = PathSegList;
  exports.PathSegMovetoAbs = PathSegMovetoAbs;
  exports.PathSegMovetoRel = PathSegMovetoRel;
  exports.PatternElement = PatternElement;
  exports.Point = Point;
  exports.PointList = PointList;
  exports.PolygonElement = PolygonElement;
  exports.PolylineElement = PolylineElement;
  exports.PreserveAspectRatio = PreserveAspectRatio;
  exports.RadialGradientElement = RadialGradientElement;
  exports.Rect = Rect;
  exports.RectElement = RectElement;
  exports.RenderingIntent = RenderingIntent;
  exports.ScriptElement = ScriptElement;
  exports.SetElement = SetElement;
  exports.StopElement = StopElement;
  exports.StringList = StringList;
  exports.StyleElement = StyleElement;
  exports.SvgSvgElement = SvgSvgElement;
  exports.SwitchElement = SwitchElement;
  exports.SymbolElement = SymbolElement;
  exports.TSpanElement = TSpanElement;
  exports.Tests = Tests;
  exports.TextElement = TextElement;
  exports.TextPathElement = TextPathElement;
  exports.TitleElement = TitleElement;
  exports.Transform = Transform;
  exports.TransformList = TransformList;
  exports.UnitTypes = UnitTypes;
  exports.UriReference = UriReference;
  exports.UseElement = UseElement;
  exports.ViewElement = ViewElement;
  exports.ViewSpec = ViewSpec;
  exports.ZoomAndPan = ZoomAndPan;
  exports.ZoomEvent = ZoomEvent;
});
