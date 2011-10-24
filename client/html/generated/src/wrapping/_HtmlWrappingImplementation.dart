// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class LevelDom {
  static AnchorElement wrapAnchorElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AnchorElementWrappingImplementation._wrap(raw);
  }

  static Animation wrapAnimation(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AnimationWrappingImplementation._wrap(raw);
  }

  static AnimationEvent wrapAnimationEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AnimationEventWrappingImplementation._wrap(raw);
  }

  static AnimationList wrapAnimationList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AnimationListWrappingImplementation._wrap(raw);
  }

  static AreaElement wrapAreaElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AreaElementWrappingImplementation._wrap(raw);
  }

  static ArrayBuffer wrapArrayBuffer(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ArrayBufferWrappingImplementation._wrap(raw);
  }

  static ArrayBufferView wrapArrayBufferView(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "ArrayBufferView":
        return new ArrayBufferViewWrappingImplementation._wrap(raw);
      case "DataView":
        return new DataViewWrappingImplementation._wrap(raw);
      case "Float32Array":
        return new Float32ArrayWrappingImplementation._wrap(raw);
      case "Float64Array":
        return new Float64ArrayWrappingImplementation._wrap(raw);
      case "Int16Array":
        return new Int16ArrayWrappingImplementation._wrap(raw);
      case "Int32Array":
        return new Int32ArrayWrappingImplementation._wrap(raw);
      case "Int8Array":
        return new Int8ArrayWrappingImplementation._wrap(raw);
      case "Uint16Array":
        return new Uint16ArrayWrappingImplementation._wrap(raw);
      case "Uint32Array":
        return new Uint32ArrayWrappingImplementation._wrap(raw);
      case "Uint8Array":
        return new Uint8ArrayWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static AudioElement wrapAudioElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioElementWrappingImplementation._wrap(raw);
  }

  static BRElement wrapBRElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new BRElementWrappingImplementation._wrap(raw);
  }

  static BarInfo wrapBarInfo(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new BarInfoWrappingImplementation._wrap(raw);
  }

  static BaseElement wrapBaseElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new BaseElementWrappingImplementation._wrap(raw);
  }

  static BeforeLoadEvent wrapBeforeLoadEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new BeforeLoadEventWrappingImplementation._wrap(raw);
  }

  static Blob wrapBlob(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "Blob":
        return new BlobWrappingImplementation._wrap(raw);
      case "File":
        return new FileWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static BlobBuilder wrapBlobBuilder(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new BlobBuilderWrappingImplementation._wrap(raw);
  }

  static BodyElement wrapBodyElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new BodyElementWrappingImplementation._wrap(raw);
  }

  static ButtonElement wrapButtonElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ButtonElementWrappingImplementation._wrap(raw);
  }

  static CDATASection wrapCDATASection(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CDATASectionWrappingImplementation._wrap(raw);
  }

  static CSSCharsetRule wrapCSSCharsetRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSCharsetRuleWrappingImplementation._wrap(raw);
  }

  static CSSFontFaceRule wrapCSSFontFaceRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSFontFaceRuleWrappingImplementation._wrap(raw);
  }

  static CSSImportRule wrapCSSImportRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSImportRuleWrappingImplementation._wrap(raw);
  }

  static CSSKeyframeRule wrapCSSKeyframeRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSKeyframeRuleWrappingImplementation._wrap(raw);
  }

  static CSSKeyframesRule wrapCSSKeyframesRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSKeyframesRuleWrappingImplementation._wrap(raw);
  }

  static CSSMatrix wrapCSSMatrix(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSMatrixWrappingImplementation._wrap(raw);
  }

  static CSSMediaRule wrapCSSMediaRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSMediaRuleWrappingImplementation._wrap(raw);
  }

  static CSSPageRule wrapCSSPageRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSPageRuleWrappingImplementation._wrap(raw);
  }

  static CSSPrimitiveValue wrapCSSPrimitiveValue(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSPrimitiveValueWrappingImplementation._wrap(raw);
  }

  static CSSRule wrapCSSRule(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "CSSCharsetRule":
        return new CSSCharsetRuleWrappingImplementation._wrap(raw);
      case "CSSFontFaceRule":
        return new CSSFontFaceRuleWrappingImplementation._wrap(raw);
      case "CSSImportRule":
        return new CSSImportRuleWrappingImplementation._wrap(raw);
      case "WebKitCSSKeyframeRule":
        return new CSSKeyframeRuleWrappingImplementation._wrap(raw);
      case "WebKitCSSKeyframesRule":
        return new CSSKeyframesRuleWrappingImplementation._wrap(raw);
      case "CSSMediaRule":
        return new CSSMediaRuleWrappingImplementation._wrap(raw);
      case "CSSPageRule":
        return new CSSPageRuleWrappingImplementation._wrap(raw);
      case "CSSRule":
        return new CSSRuleWrappingImplementation._wrap(raw);
      case "CSSStyleRule":
        return new CSSStyleRuleWrappingImplementation._wrap(raw);
      case "CSSUnknownRule":
        return new CSSUnknownRuleWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static CSSRuleList wrapCSSRuleList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSRuleListWrappingImplementation._wrap(raw);
  }

  static CSSStyleDeclaration wrapCSSStyleDeclaration(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSStyleDeclarationWrappingImplementation._wrap(raw);
  }

  static CSSStyleRule wrapCSSStyleRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSStyleRuleWrappingImplementation._wrap(raw);
  }

  static CSSStyleSheet wrapCSSStyleSheet(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSStyleSheetWrappingImplementation._wrap(raw);
  }

  static CSSTransformValue wrapCSSTransformValue(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSTransformValueWrappingImplementation._wrap(raw);
  }

  static CSSUnknownRule wrapCSSUnknownRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSUnknownRuleWrappingImplementation._wrap(raw);
  }

  static CSSValue wrapCSSValue(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "CSSPrimitiveValue":
        return new CSSPrimitiveValueWrappingImplementation._wrap(raw);
      case "WebKitCSSTransformValue":
        return new CSSTransformValueWrappingImplementation._wrap(raw);
      case "CSSValue":
        return new CSSValueWrappingImplementation._wrap(raw);
      case "CSSValueList":
        return new CSSValueListWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static CSSValueList wrapCSSValueList(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "WebKitCSSTransformValue":
        return new CSSTransformValueWrappingImplementation._wrap(raw);
      case "CSSValueList":
        return new CSSValueListWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static CanvasElement wrapCanvasElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CanvasElementWrappingImplementation._wrap(raw);
  }

  static CanvasGradient wrapCanvasGradient(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CanvasGradientWrappingImplementation._wrap(raw);
  }

  static CanvasPattern wrapCanvasPattern(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CanvasPatternWrappingImplementation._wrap(raw);
  }

  static CanvasPixelArray wrapCanvasPixelArray(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CanvasPixelArrayWrappingImplementation._wrap(raw);
  }

  static CanvasRenderingContext wrapCanvasRenderingContext(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "CanvasRenderingContext":
        return new CanvasRenderingContextWrappingImplementation._wrap(raw);
      case "CanvasRenderingContext2D":
        return new CanvasRenderingContext2DWrappingImplementation._wrap(raw);
      case "WebGLRenderingContext":
        return new WebGLRenderingContextWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static CanvasRenderingContext2D wrapCanvasRenderingContext2D(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CanvasRenderingContext2DWrappingImplementation._wrap(raw);
  }

  static CharacterData wrapCharacterData(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "CDATASection":
        return new CDATASectionWrappingImplementation._wrap(raw);
      case "CharacterData":
        return new CharacterDataWrappingImplementation._wrap(raw);
      case "Comment":
        return new CommentWrappingImplementation._wrap(raw);
      case "Text":
        return new TextWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static ClientRect wrapClientRect(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ClientRectWrappingImplementation._wrap(raw);
  }

  static Clipboard wrapClipboard(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ClipboardWrappingImplementation._wrap(raw);
  }

  static CloseEvent wrapCloseEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CloseEventWrappingImplementation._wrap(raw);
  }

  static Comment wrapComment(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CommentWrappingImplementation._wrap(raw);
  }

  static CompositionEvent wrapCompositionEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CompositionEventWrappingImplementation._wrap(raw);
  }

  static Console wrapConsole(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ConsoleWrappingImplementation._wrap(raw);
  }

  static Coordinates wrapCoordinates(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CoordinatesWrappingImplementation._wrap(raw);
  }

  static Counter wrapCounter(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CounterWrappingImplementation._wrap(raw);
  }

  static Crypto wrapCrypto(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CryptoWrappingImplementation._wrap(raw);
  }

  static CustomEvent wrapCustomEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CustomEventWrappingImplementation._wrap(raw);
  }

  static DListElement wrapDListElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DListElementWrappingImplementation._wrap(raw);
  }

  static DOMApplicationCache wrapDOMApplicationCache(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMApplicationCacheWrappingImplementation._wrap(raw);
  }

  static DOMException wrapDOMException(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMExceptionWrappingImplementation._wrap(raw);
  }

  static DOMFileSystem wrapDOMFileSystem(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMFileSystemWrappingImplementation._wrap(raw);
  }

  static DOMFileSystemSync wrapDOMFileSystemSync(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMFileSystemSyncWrappingImplementation._wrap(raw);
  }

  static DOMFormData wrapDOMFormData(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMFormDataWrappingImplementation._wrap(raw);
  }

  static DOMMimeType wrapDOMMimeType(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMMimeTypeWrappingImplementation._wrap(raw);
  }

  static DOMMimeTypeArray wrapDOMMimeTypeArray(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMMimeTypeArrayWrappingImplementation._wrap(raw);
  }

  static DOMParser wrapDOMParser(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMParserWrappingImplementation._wrap(raw);
  }

  static DOMPlugin wrapDOMPlugin(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMPluginWrappingImplementation._wrap(raw);
  }

  static DOMPluginArray wrapDOMPluginArray(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMPluginArrayWrappingImplementation._wrap(raw);
  }

  static DOMSelection wrapDOMSelection(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMSelectionWrappingImplementation._wrap(raw);
  }

  static DOMSettableTokenList wrapDOMSettableTokenList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMSettableTokenListWrappingImplementation._wrap(raw);
  }

  static DOMTokenList wrapDOMTokenList(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "DOMSettableTokenList":
        return new DOMSettableTokenListWrappingImplementation._wrap(raw);
      case "DOMTokenList":
        return new DOMTokenListWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static DOMURL wrapDOMURL(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMURLWrappingImplementation._wrap(raw);
  }

  static DataListElement wrapDataListElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DataListElementWrappingImplementation._wrap(raw);
  }

  static DataTransferItem wrapDataTransferItem(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DataTransferItemWrappingImplementation._wrap(raw);
  }

  static DataTransferItems wrapDataTransferItems(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DataTransferItemsWrappingImplementation._wrap(raw);
  }

  static DataView wrapDataView(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DataViewWrappingImplementation._wrap(raw);
  }

  static DetailsElement wrapDetailsElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DetailsElementWrappingImplementation._wrap(raw);
  }

  static DeviceMotionEvent wrapDeviceMotionEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DeviceMotionEventWrappingImplementation._wrap(raw);
  }

  static DeviceOrientationEvent wrapDeviceOrientationEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DeviceOrientationEventWrappingImplementation._wrap(raw);
  }

  static DirectoryEntry wrapDirectoryEntry(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DirectoryEntryWrappingImplementation._wrap(raw);
  }

  static DirectoryEntrySync wrapDirectoryEntrySync(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DirectoryEntrySyncWrappingImplementation._wrap(raw);
  }

  static DirectoryReader wrapDirectoryReader(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DirectoryReaderWrappingImplementation._wrap(raw);
  }

  static DirectoryReaderSync wrapDirectoryReaderSync(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DirectoryReaderSyncWrappingImplementation._wrap(raw);
  }

  static DivElement wrapDivElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DivElementWrappingImplementation._wrap(raw);
  }

  static Document wrapDocument(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DocumentWrappingImplementation._wrap(raw, raw.documentElement);
  }

  static DocumentFragment wrapDocumentFragment(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DocumentFragmentWrappingImplementation._wrap(raw);
  }

  static Element wrapElement(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "HTMLAnchorElement":
        return new AnchorElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLAppletElement*/
      case "HTMLAreaElement":
        return new AreaElementWrappingImplementation._wrap(raw);
      case "HTMLAudioElement":
        return new AudioElementWrappingImplementation._wrap(raw);
      case "HTMLBRElement":
        return new BRElementWrappingImplementation._wrap(raw);
      case "HTMLBaseElement":
        return new BaseElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLBaseFontElement*/
      case "HTMLBodyElement":
        return new BodyElementWrappingImplementation._wrap(raw);
      case "HTMLButtonElement":
        return new ButtonElementWrappingImplementation._wrap(raw);
      case "HTMLCanvasElement":
        return new CanvasElementWrappingImplementation._wrap(raw);
      case "HTMLDListElement":
        return new DListElementWrappingImplementation._wrap(raw);
      case "HTMLDataListElement":
        return new DataListElementWrappingImplementation._wrap(raw);
      case "HTMLDetailsElement":
        return new DetailsElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLDirectoryElement*/
      case "HTMLDivElement":
        return new DivElementWrappingImplementation._wrap(raw);
      case "HTMLElement":
        return new ElementWrappingImplementation._wrap(raw);
      case "HTMLEmbedElement":
        return new EmbedElementWrappingImplementation._wrap(raw);
      case "HTMLFieldSetElement":
        return new FieldSetElementWrappingImplementation._wrap(raw);
      case "HTMLFontElement":
        return new FontElementWrappingImplementation._wrap(raw);
      case "HTMLFormElement":
        return new FormElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLFrameElement*/
      /* Skipping HTMLFrameSetElement*/
      case "HTMLHRElement":
        return new HRElementWrappingImplementation._wrap(raw);
      case "HTMLHeadElement":
        return new HeadElementWrappingImplementation._wrap(raw);
      case "HTMLHeadingElement":
        return new HeadingElementWrappingImplementation._wrap(raw);
      case "HTMLHtmlElement":
        return new DocumentWrappingImplementation._wrap(raw.parentNode, raw);
      case "HTMLIFrameElement":
        return new IFrameElementWrappingImplementation._wrap(raw);
      case "HTMLImageElement":
        return new ImageElementWrappingImplementation._wrap(raw);
      case "HTMLInputElement":
        return new InputElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLIsIndexElement*/
      case "HTMLKeygenElement":
        return new KeygenElementWrappingImplementation._wrap(raw);
      case "HTMLLIElement":
        return new LIElementWrappingImplementation._wrap(raw);
      case "HTMLLabelElement":
        return new LabelElementWrappingImplementation._wrap(raw);
      case "HTMLLegendElement":
        return new LegendElementWrappingImplementation._wrap(raw);
      case "HTMLLinkElement":
        return new LinkElementWrappingImplementation._wrap(raw);
      case "HTMLMapElement":
        return new MapElementWrappingImplementation._wrap(raw);
      case "HTMLMarqueeElement":
        return new MarqueeElementWrappingImplementation._wrap(raw);
      case "HTMLMediaElement":
        return new MediaElementWrappingImplementation._wrap(raw);
      case "HTMLMenuElement":
        return new MenuElementWrappingImplementation._wrap(raw);
      case "HTMLMetaElement":
        return new MetaElementWrappingImplementation._wrap(raw);
      case "HTMLMeterElement":
        return new MeterElementWrappingImplementation._wrap(raw);
      case "HTMLModElement":
        return new ModElementWrappingImplementation._wrap(raw);
      case "HTMLOListElement":
        return new OListElementWrappingImplementation._wrap(raw);
      case "HTMLObjectElement":
        return new ObjectElementWrappingImplementation._wrap(raw);
      case "HTMLOptGroupElement":
        return new OptGroupElementWrappingImplementation._wrap(raw);
      case "HTMLOptionElement":
        return new OptionElementWrappingImplementation._wrap(raw);
      case "HTMLOutputElement":
        return new OutputElementWrappingImplementation._wrap(raw);
      case "HTMLParagraphElement":
        return new ParagraphElementWrappingImplementation._wrap(raw);
      case "HTMLParamElement":
        return new ParamElementWrappingImplementation._wrap(raw);
      case "HTMLPreElement":
        return new PreElementWrappingImplementation._wrap(raw);
      case "HTMLProgressElement":
        return new ProgressElementWrappingImplementation._wrap(raw);
      case "HTMLQuoteElement":
        return new QuoteElementWrappingImplementation._wrap(raw);
      case "HTMLScriptElement":
        return new ScriptElementWrappingImplementation._wrap(raw);
      case "HTMLSelectElement":
        return new SelectElementWrappingImplementation._wrap(raw);
      case "HTMLSourceElement":
        return new SourceElementWrappingImplementation._wrap(raw);
      case "HTMLSpanElement":
        return new SpanElementWrappingImplementation._wrap(raw);
      case "HTMLStyleElement":
        return new StyleElementWrappingImplementation._wrap(raw);
      case "HTMLTableCaptionElement":
        return new TableCaptionElementWrappingImplementation._wrap(raw);
      case "HTMLTableCellElement":
        return new TableCellElementWrappingImplementation._wrap(raw);
      case "HTMLTableColElement":
        return new TableColElementWrappingImplementation._wrap(raw);
      case "HTMLTableElement":
        return new TableElementWrappingImplementation._wrap(raw);
      case "HTMLTableRowElement":
        return new TableRowElementWrappingImplementation._wrap(raw);
      case "HTMLTableSectionElement":
        return new TableSectionElementWrappingImplementation._wrap(raw);
      case "HTMLTextAreaElement":
        return new TextAreaElementWrappingImplementation._wrap(raw);
      case "HTMLTitleElement":
        return new TitleElementWrappingImplementation._wrap(raw);
      case "HTMLTrackElement":
        return new TrackElementWrappingImplementation._wrap(raw);
      case "HTMLUListElement":
        return new UListElementWrappingImplementation._wrap(raw);
      case "HTMLUnknownElement":
        return new UnknownElementWrappingImplementation._wrap(raw);
      case "HTMLVideoElement":
        return new VideoElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static ElementList wrapElementList(raw) {
    return raw === null ? null : new FrozenElementList._wrap(raw);
  }

  static EmbedElement wrapEmbedElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EmbedElementWrappingImplementation._wrap(raw);
  }

  static Entity wrapEntity(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EntityWrappingImplementation._wrap(raw);
  }

  static EntityReference wrapEntityReference(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EntityReferenceWrappingImplementation._wrap(raw);
  }

  static EntriesCallback wrapEntriesCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EntriesCallbackWrappingImplementation._wrap(raw);
  }

  static Entry wrapEntry(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "DirectoryEntry":
        return new DirectoryEntryWrappingImplementation._wrap(raw);
      case "Entry":
        return new EntryWrappingImplementation._wrap(raw);
      case "FileEntry":
        return new FileEntryWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static EntryArray wrapEntryArray(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EntryArrayWrappingImplementation._wrap(raw);
  }

  static EntryArraySync wrapEntryArraySync(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EntryArraySyncWrappingImplementation._wrap(raw);
  }

  static EntryCallback wrapEntryCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EntryCallbackWrappingImplementation._wrap(raw);
  }

  static EntrySync wrapEntrySync(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "DirectoryEntrySync":
        return new DirectoryEntrySyncWrappingImplementation._wrap(raw);
      case "EntrySync":
        return new EntrySyncWrappingImplementation._wrap(raw);
      case "FileEntrySync":
        return new FileEntrySyncWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static ErrorCallback wrapErrorCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ErrorCallbackWrappingImplementation._wrap(raw);
  }

  static ErrorEvent wrapErrorEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ErrorEventWrappingImplementation._wrap(raw);
  }

  static Event wrapEvent(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "WebKitAnimationEvent":
        return new AnimationEventWrappingImplementation._wrap(raw);
      case "BeforeLoadEvent":
        return new BeforeLoadEventWrappingImplementation._wrap(raw);
      case "CloseEvent":
        return new CloseEventWrappingImplementation._wrap(raw);
      case "CompositionEvent":
        return new CompositionEventWrappingImplementation._wrap(raw);
      case "CustomEvent":
        return new CustomEventWrappingImplementation._wrap(raw);
      case "DeviceMotionEvent":
        return new DeviceMotionEventWrappingImplementation._wrap(raw);
      case "DeviceOrientationEvent":
        return new DeviceOrientationEventWrappingImplementation._wrap(raw);
      case "ErrorEvent":
        return new ErrorEventWrappingImplementation._wrap(raw);
      case "Event":
        return new EventWrappingImplementation._wrap(raw);
      case "HashChangeEvent":
        return new HashChangeEventWrappingImplementation._wrap(raw);
      case "IDBVersionChangeEvent":
        return new IDBVersionChangeEventWrappingImplementation._wrap(raw);
      case "KeyboardEvent":
        return new KeyboardEventWrappingImplementation._wrap(raw);
      case "MessageEvent":
        return new MessageEventWrappingImplementation._wrap(raw);
      case "MouseEvent":
        return new MouseEventWrappingImplementation._wrap(raw);
      case "MutationEvent":
        return new MutationEventWrappingImplementation._wrap(raw);
      case "OverflowEvent":
        return new OverflowEventWrappingImplementation._wrap(raw);
      case "PageTransitionEvent":
        return new PageTransitionEventWrappingImplementation._wrap(raw);
      case "PopStateEvent":
        return new PopStateEventWrappingImplementation._wrap(raw);
      case "ProgressEvent":
        return new ProgressEventWrappingImplementation._wrap(raw);
      case "SpeechInputEvent":
        return new SpeechInputEventWrappingImplementation._wrap(raw);
      case "StorageEvent":
        return new StorageEventWrappingImplementation._wrap(raw);
      case "TextEvent":
        return new TextEventWrappingImplementation._wrap(raw);
      case "TouchEvent":
        return new TouchEventWrappingImplementation._wrap(raw);
      case "WebKitTransitionEvent":
        return new TransitionEventWrappingImplementation._wrap(raw);
      case "UIEvent":
        return new UIEventWrappingImplementation._wrap(raw);
      case "WebGLContextEvent":
        return new WebGLContextEventWrappingImplementation._wrap(raw);
      case "WheelEvent":
        return new WheelEventWrappingImplementation._wrap(raw);
      case "XMLHttpRequestProgressEvent":
        return new XMLHttpRequestProgressEventWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static EventException wrapEventException(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EventExceptionWrappingImplementation._wrap(raw);
  }

  static Function wrapEventListener(raw) {
    return raw === null ? null : function(evt) { return raw(LevelDom.wrapEvent(evt)); };
  }

  static EventSource wrapEventSource(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EventSourceWrappingImplementation._wrap(raw);
  }

  static EventTarget wrapEventTarget(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      /* Skipping AbstractWorker*/
      case "HTMLAnchorElement":
        return new AnchorElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLAppletElement*/
      case "HTMLAreaElement":
        return new AreaElementWrappingImplementation._wrap(raw);
      /* Skipping Attr*/
      case "HTMLAudioElement":
        return new AudioElementWrappingImplementation._wrap(raw);
      case "HTMLBRElement":
        return new BRElementWrappingImplementation._wrap(raw);
      case "HTMLBaseElement":
        return new BaseElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLBaseFontElement*/
      case "HTMLBodyElement":
        return new BodyElementWrappingImplementation._wrap(raw);
      case "HTMLButtonElement":
        return new ButtonElementWrappingImplementation._wrap(raw);
      case "CDATASection":
        return new CDATASectionWrappingImplementation._wrap(raw);
      case "HTMLCanvasElement":
        return new CanvasElementWrappingImplementation._wrap(raw);
      case "CharacterData":
        return new CharacterDataWrappingImplementation._wrap(raw);
      case "Comment":
        return new CommentWrappingImplementation._wrap(raw);
      case "HTMLDListElement":
        return new DListElementWrappingImplementation._wrap(raw);
      case "DOMApplicationCache":
        return new DOMApplicationCacheWrappingImplementation._wrap(raw);
      case "HTMLDataListElement":
        return new DataListElementWrappingImplementation._wrap(raw);
      case "HTMLDetailsElement":
        return new DetailsElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLDirectoryElement*/
      case "HTMLDivElement":
        return new DivElementWrappingImplementation._wrap(raw);
      case "HTMLDocument":
        return new DocumentWrappingImplementation._wrap(raw, raw.documentElement);
      case "DocumentFragment":
        return new DocumentFragmentWrappingImplementation._wrap(raw);
      /* Skipping DocumentType*/
      case "HTMLElement":
        return new ElementWrappingImplementation._wrap(raw);
      case "HTMLEmbedElement":
        return new EmbedElementWrappingImplementation._wrap(raw);
      case "Entity":
        return new EntityWrappingImplementation._wrap(raw);
      case "EntityReference":
        return new EntityReferenceWrappingImplementation._wrap(raw);
      case "EventSource":
        return new EventSourceWrappingImplementation._wrap(raw);
      case "EventTarget":
        return new EventTargetWrappingImplementation._wrap(raw);
      case "HTMLFieldSetElement":
        return new FieldSetElementWrappingImplementation._wrap(raw);
      case "HTMLFontElement":
        return new FontElementWrappingImplementation._wrap(raw);
      case "HTMLFormElement":
        return new FormElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLFrameElement*/
      /* Skipping HTMLFrameSetElement*/
      case "HTMLHRElement":
        return new HRElementWrappingImplementation._wrap(raw);
      case "HTMLHeadElement":
        return new HeadElementWrappingImplementation._wrap(raw);
      case "HTMLHeadingElement":
        return new HeadingElementWrappingImplementation._wrap(raw);
      case "HTMLHtmlElement":
        return new DocumentWrappingImplementation._wrap(raw.parentNode, raw);
      case "HTMLIFrameElement":
        return new IFrameElementWrappingImplementation._wrap(raw);
      case "HTMLImageElement":
        return new ImageElementWrappingImplementation._wrap(raw);
      case "HTMLInputElement":
        return new InputElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLIsIndexElement*/
      case "HTMLKeygenElement":
        return new KeygenElementWrappingImplementation._wrap(raw);
      case "HTMLLIElement":
        return new LIElementWrappingImplementation._wrap(raw);
      case "HTMLLabelElement":
        return new LabelElementWrappingImplementation._wrap(raw);
      case "HTMLLegendElement":
        return new LegendElementWrappingImplementation._wrap(raw);
      case "HTMLLinkElement":
        return new LinkElementWrappingImplementation._wrap(raw);
      case "HTMLMapElement":
        return new MapElementWrappingImplementation._wrap(raw);
      case "HTMLMarqueeElement":
        return new MarqueeElementWrappingImplementation._wrap(raw);
      case "HTMLMediaElement":
        return new MediaElementWrappingImplementation._wrap(raw);
      case "HTMLMenuElement":
        return new MenuElementWrappingImplementation._wrap(raw);
      case "MessagePort":
        return new MessagePortWrappingImplementation._wrap(raw);
      case "HTMLMetaElement":
        return new MetaElementWrappingImplementation._wrap(raw);
      case "HTMLMeterElement":
        return new MeterElementWrappingImplementation._wrap(raw);
      case "HTMLModElement":
        return new ModElementWrappingImplementation._wrap(raw);
      case "Node":
        return new NodeWrappingImplementation._wrap(raw);
      case "Notation":
        return new NotationWrappingImplementation._wrap(raw);
      case "Notification":
        return new NotificationWrappingImplementation._wrap(raw);
      case "HTMLOListElement":
        return new OListElementWrappingImplementation._wrap(raw);
      case "HTMLObjectElement":
        return new ObjectElementWrappingImplementation._wrap(raw);
      case "HTMLOptGroupElement":
        return new OptGroupElementWrappingImplementation._wrap(raw);
      case "HTMLOptionElement":
        return new OptionElementWrappingImplementation._wrap(raw);
      case "HTMLOutputElement":
        return new OutputElementWrappingImplementation._wrap(raw);
      case "HTMLParagraphElement":
        return new ParagraphElementWrappingImplementation._wrap(raw);
      case "HTMLParamElement":
        return new ParamElementWrappingImplementation._wrap(raw);
      case "HTMLPreElement":
        return new PreElementWrappingImplementation._wrap(raw);
      case "ProcessingInstruction":
        return new ProcessingInstructionWrappingImplementation._wrap(raw);
      case "HTMLProgressElement":
        return new ProgressElementWrappingImplementation._wrap(raw);
      case "HTMLQuoteElement":
        return new QuoteElementWrappingImplementation._wrap(raw);
      case "HTMLScriptElement":
        return new ScriptElementWrappingImplementation._wrap(raw);
      case "HTMLSelectElement":
        return new SelectElementWrappingImplementation._wrap(raw);
      case "SharedWorker":
        return new SharedWorkerWrappingImplementation._wrap(raw);
      case "HTMLSourceElement":
        return new SourceElementWrappingImplementation._wrap(raw);
      case "HTMLSpanElement":
        return new SpanElementWrappingImplementation._wrap(raw);
      case "HTMLStyleElement":
        return new StyleElementWrappingImplementation._wrap(raw);
      case "HTMLTableCaptionElement":
        return new TableCaptionElementWrappingImplementation._wrap(raw);
      case "HTMLTableCellElement":
        return new TableCellElementWrappingImplementation._wrap(raw);
      case "HTMLTableColElement":
        return new TableColElementWrappingImplementation._wrap(raw);
      case "HTMLTableElement":
        return new TableElementWrappingImplementation._wrap(raw);
      case "HTMLTableRowElement":
        return new TableRowElementWrappingImplementation._wrap(raw);
      case "HTMLTableSectionElement":
        return new TableSectionElementWrappingImplementation._wrap(raw);
      case "Text":
        return new TextWrappingImplementation._wrap(raw);
      case "HTMLTextAreaElement":
        return new TextAreaElementWrappingImplementation._wrap(raw);
      case "HTMLTitleElement":
        return new TitleElementWrappingImplementation._wrap(raw);
      case "HTMLTrackElement":
        return new TrackElementWrappingImplementation._wrap(raw);
      case "HTMLUListElement":
        return new UListElementWrappingImplementation._wrap(raw);
      case "HTMLUnknownElement":
        return new UnknownElementWrappingImplementation._wrap(raw);
      case "HTMLVideoElement":
        return new VideoElementWrappingImplementation._wrap(raw);
      case "WebSocket":
        return new WebSocketWrappingImplementation._wrap(raw);
      case "Window":
        return new WindowWrappingImplementation._wrap(raw);
      case "Worker":
        return new WorkerWrappingImplementation._wrap(raw);
      case "XMLHttpRequest":
        return new XMLHttpRequestWrappingImplementation._wrap(raw);
      case "XMLHttpRequestUpload":
        return new XMLHttpRequestUploadWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static FieldSetElement wrapFieldSetElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FieldSetElementWrappingImplementation._wrap(raw);
  }

  static File wrapFile(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileWrappingImplementation._wrap(raw);
  }

  static FileCallback wrapFileCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileCallbackWrappingImplementation._wrap(raw);
  }

  static FileEntry wrapFileEntry(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileEntryWrappingImplementation._wrap(raw);
  }

  static FileEntrySync wrapFileEntrySync(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileEntrySyncWrappingImplementation._wrap(raw);
  }

  static FileError wrapFileError(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileErrorWrappingImplementation._wrap(raw);
  }

  static FileException wrapFileException(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileExceptionWrappingImplementation._wrap(raw);
  }

  static FileList wrapFileList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileListWrappingImplementation._wrap(raw);
  }

  static FileReader wrapFileReader(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileReaderWrappingImplementation._wrap(raw);
  }

  static FileReaderSync wrapFileReaderSync(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileReaderSyncWrappingImplementation._wrap(raw);
  }

  static FileSystemCallback wrapFileSystemCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileSystemCallbackWrappingImplementation._wrap(raw);
  }

  static FileWriter wrapFileWriter(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileWriterWrappingImplementation._wrap(raw);
  }

  static FileWriterCallback wrapFileWriterCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileWriterCallbackWrappingImplementation._wrap(raw);
  }

  static FileWriterSync wrapFileWriterSync(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileWriterSyncWrappingImplementation._wrap(raw);
  }

  static Flags wrapFlags(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FlagsWrappingImplementation._wrap(raw);
  }

  static Float32Array wrapFloat32Array(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new Float32ArrayWrappingImplementation._wrap(raw);
  }

  static Float64Array wrapFloat64Array(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new Float64ArrayWrappingImplementation._wrap(raw);
  }

  static FontElement wrapFontElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FontElementWrappingImplementation._wrap(raw);
  }

  static FormElement wrapFormElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FormElementWrappingImplementation._wrap(raw);
  }

  static Geolocation wrapGeolocation(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new GeolocationWrappingImplementation._wrap(raw);
  }

  static Geoposition wrapGeoposition(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new GeopositionWrappingImplementation._wrap(raw);
  }

  static HRElement wrapHRElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new HRElementWrappingImplementation._wrap(raw);
  }

  static HTMLAllCollection wrapHTMLAllCollection(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new HTMLAllCollectionWrappingImplementation._wrap(raw);
  }

  static HashChangeEvent wrapHashChangeEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new HashChangeEventWrappingImplementation._wrap(raw);
  }

  static HeadElement wrapHeadElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new HeadElementWrappingImplementation._wrap(raw);
  }

  static HeadingElement wrapHeadingElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new HeadingElementWrappingImplementation._wrap(raw);
  }

  static History wrapHistory(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new HistoryWrappingImplementation._wrap(raw);
  }

  static IDBAny wrapIDBAny(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBAnyWrappingImplementation._wrap(raw);
  }

  static IDBCursor wrapIDBCursor(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "IDBCursor":
        return new IDBCursorWrappingImplementation._wrap(raw);
      case "IDBCursorWithValue":
        return new IDBCursorWithValueWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static IDBCursorWithValue wrapIDBCursorWithValue(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBCursorWithValueWrappingImplementation._wrap(raw);
  }

  static IDBDatabase wrapIDBDatabase(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBDatabaseWrappingImplementation._wrap(raw);
  }

  static IDBDatabaseError wrapIDBDatabaseError(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBDatabaseErrorWrappingImplementation._wrap(raw);
  }

  static IDBDatabaseException wrapIDBDatabaseException(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBDatabaseExceptionWrappingImplementation._wrap(raw);
  }

  static IDBFactory wrapIDBFactory(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBFactoryWrappingImplementation._wrap(raw);
  }

  static IDBIndex wrapIDBIndex(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBIndexWrappingImplementation._wrap(raw);
  }

  static IDBKey wrapIDBKey(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBKeyWrappingImplementation._wrap(raw);
  }

  static IDBKeyRange wrapIDBKeyRange(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBKeyRangeWrappingImplementation._wrap(raw);
  }

  static IDBObjectStore wrapIDBObjectStore(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBObjectStoreWrappingImplementation._wrap(raw);
  }

  static IDBRequest wrapIDBRequest(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "IDBRequest":
        return new IDBRequestWrappingImplementation._wrap(raw);
      case "IDBVersionChangeRequest":
        return new IDBVersionChangeRequestWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static IDBTransaction wrapIDBTransaction(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBTransactionWrappingImplementation._wrap(raw);
  }

  static IDBVersionChangeEvent wrapIDBVersionChangeEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBVersionChangeEventWrappingImplementation._wrap(raw);
  }

  static IDBVersionChangeRequest wrapIDBVersionChangeRequest(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBVersionChangeRequestWrappingImplementation._wrap(raw);
  }

  static IFrameElement wrapIFrameElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IFrameElementWrappingImplementation._wrap(raw);
  }

  static ImageData wrapImageData(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ImageDataWrappingImplementation._wrap(raw);
  }

  static ImageElement wrapImageElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ImageElementWrappingImplementation._wrap(raw);
  }

  static InputElement wrapInputElement(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "HTMLInputElement":
        return new InputElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLIsIndexElement*/
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static Int16Array wrapInt16Array(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new Int16ArrayWrappingImplementation._wrap(raw);
  }

  static Int32Array wrapInt32Array(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new Int32ArrayWrappingImplementation._wrap(raw);
  }

  static Int8Array wrapInt8Array(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new Int8ArrayWrappingImplementation._wrap(raw);
  }

  static KeyboardEvent wrapKeyboardEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new KeyboardEventWrappingImplementation._wrap(raw);
  }

  static KeygenElement wrapKeygenElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new KeygenElementWrappingImplementation._wrap(raw);
  }

  static LIElement wrapLIElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new LIElementWrappingImplementation._wrap(raw);
  }

  static LabelElement wrapLabelElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new LabelElementWrappingImplementation._wrap(raw);
  }

  static LegendElement wrapLegendElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new LegendElementWrappingImplementation._wrap(raw);
  }

  static LinkElement wrapLinkElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new LinkElementWrappingImplementation._wrap(raw);
  }

  static LocalMediaStream wrapLocalMediaStream(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new LocalMediaStreamWrappingImplementation._wrap(raw);
  }

  static Location wrapLocation(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new LocationWrappingImplementation._wrap(raw);
  }

  static LoseContext wrapLoseContext(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new LoseContextWrappingImplementation._wrap(raw);
  }

  static MapElement wrapMapElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MapElementWrappingImplementation._wrap(raw);
  }

  static MarqueeElement wrapMarqueeElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MarqueeElementWrappingImplementation._wrap(raw);
  }

  static MediaElement wrapMediaElement(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "HTMLAudioElement":
        return new AudioElementWrappingImplementation._wrap(raw);
      case "HTMLMediaElement":
        return new MediaElementWrappingImplementation._wrap(raw);
      case "HTMLVideoElement":
        return new VideoElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static MediaError wrapMediaError(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MediaErrorWrappingImplementation._wrap(raw);
  }

  static MediaList wrapMediaList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MediaListWrappingImplementation._wrap(raw);
  }

  static MediaQueryList wrapMediaQueryList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MediaQueryListWrappingImplementation._wrap(raw);
  }

  static MediaQueryListListener wrapMediaQueryListListener(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MediaQueryListListenerWrappingImplementation._wrap(raw);
  }

  static MediaStream wrapMediaStream(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "LocalMediaStream":
        return new LocalMediaStreamWrappingImplementation._wrap(raw);
      case "MediaStream":
        return new MediaStreamWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static MediaStreamList wrapMediaStreamList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MediaStreamListWrappingImplementation._wrap(raw);
  }

  static MediaStreamTrack wrapMediaStreamTrack(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MediaStreamTrackWrappingImplementation._wrap(raw);
  }

  static MediaStreamTrackList wrapMediaStreamTrackList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MediaStreamTrackListWrappingImplementation._wrap(raw);
  }

  static MenuElement wrapMenuElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MenuElementWrappingImplementation._wrap(raw);
  }

  static MessageChannel wrapMessageChannel(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MessageChannelWrappingImplementation._wrap(raw);
  }

  static MessageEvent wrapMessageEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MessageEventWrappingImplementation._wrap(raw);
  }

  static MessagePort wrapMessagePort(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MessagePortWrappingImplementation._wrap(raw);
  }

  static MetaElement wrapMetaElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MetaElementWrappingImplementation._wrap(raw);
  }

  static Metadata wrapMetadata(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MetadataWrappingImplementation._wrap(raw);
  }

  static MetadataCallback wrapMetadataCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MetadataCallbackWrappingImplementation._wrap(raw);
  }

  static MeterElement wrapMeterElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MeterElementWrappingImplementation._wrap(raw);
  }

  static ModElement wrapModElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ModElementWrappingImplementation._wrap(raw);
  }

  static MouseEvent wrapMouseEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MouseEventWrappingImplementation._wrap(raw);
  }

  static MutationEvent wrapMutationEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MutationEventWrappingImplementation._wrap(raw);
  }

  static MutationRecord wrapMutationRecord(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MutationRecordWrappingImplementation._wrap(raw);
  }

  static Navigator wrapNavigator(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new NavigatorWrappingImplementation._wrap(raw);
  }

  static NavigatorUserMediaError wrapNavigatorUserMediaError(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new NavigatorUserMediaErrorWrappingImplementation._wrap(raw);
  }

  static NavigatorUserMediaErrorCallback wrapNavigatorUserMediaErrorCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new NavigatorUserMediaErrorCallbackWrappingImplementation._wrap(raw);
  }

  static NavigatorUserMediaSuccessCallback wrapNavigatorUserMediaSuccessCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new NavigatorUserMediaSuccessCallbackWrappingImplementation._wrap(raw);
  }

  static Node wrapNode(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "HTMLAnchorElement":
        return new AnchorElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLAppletElement*/
      case "HTMLAreaElement":
        return new AreaElementWrappingImplementation._wrap(raw);
      /* Skipping Attr*/
      case "HTMLAudioElement":
        return new AudioElementWrappingImplementation._wrap(raw);
      case "HTMLBRElement":
        return new BRElementWrappingImplementation._wrap(raw);
      case "HTMLBaseElement":
        return new BaseElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLBaseFontElement*/
      case "HTMLBodyElement":
        return new BodyElementWrappingImplementation._wrap(raw);
      case "HTMLButtonElement":
        return new ButtonElementWrappingImplementation._wrap(raw);
      case "CDATASection":
        return new CDATASectionWrappingImplementation._wrap(raw);
      case "HTMLCanvasElement":
        return new CanvasElementWrappingImplementation._wrap(raw);
      case "CharacterData":
        return new CharacterDataWrappingImplementation._wrap(raw);
      case "Comment":
        return new CommentWrappingImplementation._wrap(raw);
      case "HTMLDListElement":
        return new DListElementWrappingImplementation._wrap(raw);
      case "HTMLDataListElement":
        return new DataListElementWrappingImplementation._wrap(raw);
      case "HTMLDetailsElement":
        return new DetailsElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLDirectoryElement*/
      case "HTMLDivElement":
        return new DivElementWrappingImplementation._wrap(raw);
      case "HTMLDocument":
        return new DocumentWrappingImplementation._wrap(raw, raw.documentElement);
      case "DocumentFragment":
        return new DocumentFragmentWrappingImplementation._wrap(raw);
      /* Skipping DocumentType*/
      case "HTMLElement":
        return new ElementWrappingImplementation._wrap(raw);
      case "HTMLEmbedElement":
        return new EmbedElementWrappingImplementation._wrap(raw);
      case "Entity":
        return new EntityWrappingImplementation._wrap(raw);
      case "EntityReference":
        return new EntityReferenceWrappingImplementation._wrap(raw);
      case "HTMLFieldSetElement":
        return new FieldSetElementWrappingImplementation._wrap(raw);
      case "HTMLFontElement":
        return new FontElementWrappingImplementation._wrap(raw);
      case "HTMLFormElement":
        return new FormElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLFrameElement*/
      /* Skipping HTMLFrameSetElement*/
      case "HTMLHRElement":
        return new HRElementWrappingImplementation._wrap(raw);
      case "HTMLHeadElement":
        return new HeadElementWrappingImplementation._wrap(raw);
      case "HTMLHeadingElement":
        return new HeadingElementWrappingImplementation._wrap(raw);
      case "HTMLHtmlElement":
        return new DocumentWrappingImplementation._wrap(raw.parentNode, raw);
      case "HTMLIFrameElement":
        return new IFrameElementWrappingImplementation._wrap(raw);
      case "HTMLImageElement":
        return new ImageElementWrappingImplementation._wrap(raw);
      case "HTMLInputElement":
        return new InputElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLIsIndexElement*/
      case "HTMLKeygenElement":
        return new KeygenElementWrappingImplementation._wrap(raw);
      case "HTMLLIElement":
        return new LIElementWrappingImplementation._wrap(raw);
      case "HTMLLabelElement":
        return new LabelElementWrappingImplementation._wrap(raw);
      case "HTMLLegendElement":
        return new LegendElementWrappingImplementation._wrap(raw);
      case "HTMLLinkElement":
        return new LinkElementWrappingImplementation._wrap(raw);
      case "HTMLMapElement":
        return new MapElementWrappingImplementation._wrap(raw);
      case "HTMLMarqueeElement":
        return new MarqueeElementWrappingImplementation._wrap(raw);
      case "HTMLMediaElement":
        return new MediaElementWrappingImplementation._wrap(raw);
      case "HTMLMenuElement":
        return new MenuElementWrappingImplementation._wrap(raw);
      case "HTMLMetaElement":
        return new MetaElementWrappingImplementation._wrap(raw);
      case "HTMLMeterElement":
        return new MeterElementWrappingImplementation._wrap(raw);
      case "HTMLModElement":
        return new ModElementWrappingImplementation._wrap(raw);
      case "Node":
        return new NodeWrappingImplementation._wrap(raw);
      case "Notation":
        return new NotationWrappingImplementation._wrap(raw);
      case "HTMLOListElement":
        return new OListElementWrappingImplementation._wrap(raw);
      case "HTMLObjectElement":
        return new ObjectElementWrappingImplementation._wrap(raw);
      case "HTMLOptGroupElement":
        return new OptGroupElementWrappingImplementation._wrap(raw);
      case "HTMLOptionElement":
        return new OptionElementWrappingImplementation._wrap(raw);
      case "HTMLOutputElement":
        return new OutputElementWrappingImplementation._wrap(raw);
      case "HTMLParagraphElement":
        return new ParagraphElementWrappingImplementation._wrap(raw);
      case "HTMLParamElement":
        return new ParamElementWrappingImplementation._wrap(raw);
      case "HTMLPreElement":
        return new PreElementWrappingImplementation._wrap(raw);
      case "ProcessingInstruction":
        return new ProcessingInstructionWrappingImplementation._wrap(raw);
      case "HTMLProgressElement":
        return new ProgressElementWrappingImplementation._wrap(raw);
      case "HTMLQuoteElement":
        return new QuoteElementWrappingImplementation._wrap(raw);
      case "HTMLScriptElement":
        return new ScriptElementWrappingImplementation._wrap(raw);
      case "HTMLSelectElement":
        return new SelectElementWrappingImplementation._wrap(raw);
      case "HTMLSourceElement":
        return new SourceElementWrappingImplementation._wrap(raw);
      case "HTMLSpanElement":
        return new SpanElementWrappingImplementation._wrap(raw);
      case "HTMLStyleElement":
        return new StyleElementWrappingImplementation._wrap(raw);
      case "HTMLTableCaptionElement":
        return new TableCaptionElementWrappingImplementation._wrap(raw);
      case "HTMLTableCellElement":
        return new TableCellElementWrappingImplementation._wrap(raw);
      case "HTMLTableColElement":
        return new TableColElementWrappingImplementation._wrap(raw);
      case "HTMLTableElement":
        return new TableElementWrappingImplementation._wrap(raw);
      case "HTMLTableRowElement":
        return new TableRowElementWrappingImplementation._wrap(raw);
      case "HTMLTableSectionElement":
        return new TableSectionElementWrappingImplementation._wrap(raw);
      case "Text":
        return new TextWrappingImplementation._wrap(raw);
      case "HTMLTextAreaElement":
        return new TextAreaElementWrappingImplementation._wrap(raw);
      case "HTMLTitleElement":
        return new TitleElementWrappingImplementation._wrap(raw);
      case "HTMLTrackElement":
        return new TrackElementWrappingImplementation._wrap(raw);
      case "HTMLUListElement":
        return new UListElementWrappingImplementation._wrap(raw);
      case "HTMLUnknownElement":
        return new UnknownElementWrappingImplementation._wrap(raw);
      case "HTMLVideoElement":
        return new VideoElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static Notation wrapNotation(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new NotationWrappingImplementation._wrap(raw);
  }

  static Notification wrapNotification(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new NotificationWrappingImplementation._wrap(raw);
  }

  static NotificationCenter wrapNotificationCenter(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new NotificationCenterWrappingImplementation._wrap(raw);
  }

  static OESStandardDerivatives wrapOESStandardDerivatives(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OESStandardDerivativesWrappingImplementation._wrap(raw);
  }

  static OESTextureFloat wrapOESTextureFloat(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OESTextureFloatWrappingImplementation._wrap(raw);
  }

  static OESVertexArrayObject wrapOESVertexArrayObject(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OESVertexArrayObjectWrappingImplementation._wrap(raw);
  }

  static OListElement wrapOListElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OListElementWrappingImplementation._wrap(raw);
  }

  static ObjectElement wrapObjectElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ObjectElementWrappingImplementation._wrap(raw);
  }

  static OperationNotAllowedException wrapOperationNotAllowedException(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OperationNotAllowedExceptionWrappingImplementation._wrap(raw);
  }

  static OptGroupElement wrapOptGroupElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OptGroupElementWrappingImplementation._wrap(raw);
  }

  static OptionElement wrapOptionElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OptionElementWrappingImplementation._wrap(raw);
  }

  static OutputElement wrapOutputElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OutputElementWrappingImplementation._wrap(raw);
  }

  static OverflowEvent wrapOverflowEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OverflowEventWrappingImplementation._wrap(raw);
  }

  static PageTransitionEvent wrapPageTransitionEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new PageTransitionEventWrappingImplementation._wrap(raw);
  }

  static ParagraphElement wrapParagraphElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ParagraphElementWrappingImplementation._wrap(raw);
  }

  static ParamElement wrapParamElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ParamElementWrappingImplementation._wrap(raw);
  }

  static Point wrapPoint(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new PointWrappingImplementation._wrap(raw);
  }

  static PopStateEvent wrapPopStateEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new PopStateEventWrappingImplementation._wrap(raw);
  }

  static PositionCallback wrapPositionCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new PositionCallbackWrappingImplementation._wrap(raw);
  }

  static PositionError wrapPositionError(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new PositionErrorWrappingImplementation._wrap(raw);
  }

  static PositionErrorCallback wrapPositionErrorCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new PositionErrorCallbackWrappingImplementation._wrap(raw);
  }

  static PreElement wrapPreElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new PreElementWrappingImplementation._wrap(raw);
  }

  static ProcessingInstruction wrapProcessingInstruction(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ProcessingInstructionWrappingImplementation._wrap(raw);
  }

  static ProgressElement wrapProgressElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ProgressElementWrappingImplementation._wrap(raw);
  }

  static ProgressEvent wrapProgressEvent(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "ProgressEvent":
        return new ProgressEventWrappingImplementation._wrap(raw);
      case "XMLHttpRequestProgressEvent":
        return new XMLHttpRequestProgressEventWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static QuoteElement wrapQuoteElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new QuoteElementWrappingImplementation._wrap(raw);
  }

  static RGBColor wrapRGBColor(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new RGBColorWrappingImplementation._wrap(raw);
  }

  static Range wrapRange(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new RangeWrappingImplementation._wrap(raw);
  }

  static RangeException wrapRangeException(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new RangeExceptionWrappingImplementation._wrap(raw);
  }

  static Rect wrapRect(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new RectWrappingImplementation._wrap(raw);
  }

  static Screen wrapScreen(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ScreenWrappingImplementation._wrap(raw);
  }

  static ScriptElement wrapScriptElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ScriptElementWrappingImplementation._wrap(raw);
  }

  static SelectElement wrapSelectElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SelectElementWrappingImplementation._wrap(raw);
  }

  static SharedWorker wrapSharedWorker(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SharedWorkerWrappingImplementation._wrap(raw);
  }

  static SourceElement wrapSourceElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SourceElementWrappingImplementation._wrap(raw);
  }

  static SpanElement wrapSpanElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SpanElementWrappingImplementation._wrap(raw);
  }

  static SpeechInputEvent wrapSpeechInputEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SpeechInputEventWrappingImplementation._wrap(raw);
  }

  static SpeechInputResult wrapSpeechInputResult(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SpeechInputResultWrappingImplementation._wrap(raw);
  }

  static SpeechInputResultList wrapSpeechInputResultList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SpeechInputResultListWrappingImplementation._wrap(raw);
  }

  static Storage wrapStorage(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StorageWrappingImplementation._wrap(raw);
  }

  static StorageEvent wrapStorageEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StorageEventWrappingImplementation._wrap(raw);
  }

  static StorageInfo wrapStorageInfo(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StorageInfoWrappingImplementation._wrap(raw);
  }

  static StorageInfoErrorCallback wrapStorageInfoErrorCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StorageInfoErrorCallbackWrappingImplementation._wrap(raw);
  }

  static StorageInfoQuotaCallback wrapStorageInfoQuotaCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StorageInfoQuotaCallbackWrappingImplementation._wrap(raw);
  }

  static StorageInfoUsageCallback wrapStorageInfoUsageCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StorageInfoUsageCallbackWrappingImplementation._wrap(raw);
  }

  static StringCallback wrapStringCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StringCallbackWrappingImplementation._wrap(raw);
  }

  static StyleElement wrapStyleElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StyleElementWrappingImplementation._wrap(raw);
  }

  static StyleMedia wrapStyleMedia(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StyleMediaWrappingImplementation._wrap(raw);
  }

  static StyleSheet wrapStyleSheet(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "CSSStyleSheet":
        return new CSSStyleSheetWrappingImplementation._wrap(raw);
      case "StyleSheet":
        return new StyleSheetWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static StyleSheetList wrapStyleSheetList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StyleSheetListWrappingImplementation._wrap(raw);
  }

  static TableCaptionElement wrapTableCaptionElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TableCaptionElementWrappingImplementation._wrap(raw);
  }

  static TableCellElement wrapTableCellElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TableCellElementWrappingImplementation._wrap(raw);
  }

  static TableColElement wrapTableColElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TableColElementWrappingImplementation._wrap(raw);
  }

  static TableElement wrapTableElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TableElementWrappingImplementation._wrap(raw);
  }

  static TableRowElement wrapTableRowElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TableRowElementWrappingImplementation._wrap(raw);
  }

  static TableSectionElement wrapTableSectionElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TableSectionElementWrappingImplementation._wrap(raw);
  }

  static Text wrapText(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "CDATASection":
        return new CDATASectionWrappingImplementation._wrap(raw);
      case "Text":
        return new TextWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static TextAreaElement wrapTextAreaElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TextAreaElementWrappingImplementation._wrap(raw);
  }

  static TextEvent wrapTextEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TextEventWrappingImplementation._wrap(raw);
  }

  static TextMetrics wrapTextMetrics(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TextMetricsWrappingImplementation._wrap(raw);
  }

  static TimeRanges wrapTimeRanges(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TimeRangesWrappingImplementation._wrap(raw);
  }

  static TitleElement wrapTitleElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TitleElementWrappingImplementation._wrap(raw);
  }

  static Touch wrapTouch(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TouchWrappingImplementation._wrap(raw);
  }

  static TouchEvent wrapTouchEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TouchEventWrappingImplementation._wrap(raw);
  }

  static TouchList wrapTouchList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TouchListWrappingImplementation._wrap(raw);
  }

  static TrackElement wrapTrackElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TrackElementWrappingImplementation._wrap(raw);
  }

  static TransitionEvent wrapTransitionEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TransitionEventWrappingImplementation._wrap(raw);
  }

  static UIEvent wrapUIEvent(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "CompositionEvent":
        return new CompositionEventWrappingImplementation._wrap(raw);
      case "KeyboardEvent":
        return new KeyboardEventWrappingImplementation._wrap(raw);
      case "MouseEvent":
        return new MouseEventWrappingImplementation._wrap(raw);
      case "TextEvent":
        return new TextEventWrappingImplementation._wrap(raw);
      case "TouchEvent":
        return new TouchEventWrappingImplementation._wrap(raw);
      case "UIEvent":
        return new UIEventWrappingImplementation._wrap(raw);
      case "WheelEvent":
        return new WheelEventWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static UListElement wrapUListElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new UListElementWrappingImplementation._wrap(raw);
  }

  static Uint16Array wrapUint16Array(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new Uint16ArrayWrappingImplementation._wrap(raw);
  }

  static Uint32Array wrapUint32Array(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new Uint32ArrayWrappingImplementation._wrap(raw);
  }

  static Uint8Array wrapUint8Array(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new Uint8ArrayWrappingImplementation._wrap(raw);
  }

  static UnknownElement wrapUnknownElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new UnknownElementWrappingImplementation._wrap(raw);
  }

  static ValidityState wrapValidityState(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ValidityStateWrappingImplementation._wrap(raw);
  }

  static VideoElement wrapVideoElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new VideoElementWrappingImplementation._wrap(raw);
  }

  static VoidCallback wrapVoidCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new VoidCallbackWrappingImplementation._wrap(raw);
  }

  static WebGLActiveInfo wrapWebGLActiveInfo(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLActiveInfoWrappingImplementation._wrap(raw);
  }

  static WebGLBuffer wrapWebGLBuffer(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLBufferWrappingImplementation._wrap(raw);
  }

  static WebGLContextAttributes wrapWebGLContextAttributes(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLContextAttributesWrappingImplementation._wrap(raw);
  }

  static WebGLContextEvent wrapWebGLContextEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLContextEventWrappingImplementation._wrap(raw);
  }

  static WebGLFramebuffer wrapWebGLFramebuffer(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLFramebufferWrappingImplementation._wrap(raw);
  }

  static WebGLProgram wrapWebGLProgram(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLProgramWrappingImplementation._wrap(raw);
  }

  static WebGLRenderbuffer wrapWebGLRenderbuffer(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLRenderbufferWrappingImplementation._wrap(raw);
  }

  static WebGLRenderingContext wrapWebGLRenderingContext(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLRenderingContextWrappingImplementation._wrap(raw);
  }

  static WebGLShader wrapWebGLShader(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLShaderWrappingImplementation._wrap(raw);
  }

  static WebGLTexture wrapWebGLTexture(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLTextureWrappingImplementation._wrap(raw);
  }

  static WebGLUniformLocation wrapWebGLUniformLocation(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLUniformLocationWrappingImplementation._wrap(raw);
  }

  static WebGLVertexArrayObjectOES wrapWebGLVertexArrayObjectOES(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLVertexArrayObjectOESWrappingImplementation._wrap(raw);
  }

  static WebSocket wrapWebSocket(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebSocketWrappingImplementation._wrap(raw);
  }

  static WheelEvent wrapWheelEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WheelEventWrappingImplementation._wrap(raw);
  }

  static Window wrapWindow(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WindowWrappingImplementation._wrap(raw);
  }

  static Worker wrapWorker(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WorkerWrappingImplementation._wrap(raw);
  }

  static XMLHttpRequest wrapXMLHttpRequest(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new XMLHttpRequestWrappingImplementation._wrap(raw);
  }

  static XMLHttpRequestException wrapXMLHttpRequestException(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new XMLHttpRequestExceptionWrappingImplementation._wrap(raw);
  }

  static XMLHttpRequestProgressEvent wrapXMLHttpRequestProgressEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new XMLHttpRequestProgressEventWrappingImplementation._wrap(raw);
  }

  static XMLHttpRequestUpload wrapXMLHttpRequestUpload(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new XMLHttpRequestUploadWrappingImplementation._wrap(raw);
  }

  static unwrapMaybePrimitive(raw) {
    return raw is DOMWrapperBase ? raw._ptr : raw;
  }

  static unwrap(raw) {
    return raw === null ? null : raw._ptr;
  }


  static void initialize(var rawWindow) {
    secretWindow = wrapWindow(rawWindow);
    secretDocument = wrapDocument(rawWindow.document);
  }

}
