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

  static AudioBuffer wrapAudioBuffer(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioBufferWrappingImplementation._wrap(raw);
  }

  // Skipped AudioBufferCallback
  static AudioBufferSourceNode wrapAudioBufferSourceNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioBufferSourceNodeWrappingImplementation._wrap(raw);
  }

  static AudioChannelMerger wrapAudioChannelMerger(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioChannelMergerWrappingImplementation._wrap(raw);
  }

  static AudioChannelSplitter wrapAudioChannelSplitter(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioChannelSplitterWrappingImplementation._wrap(raw);
  }

  static AudioContext wrapAudioContext(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioContextWrappingImplementation._wrap(raw);
  }

  static AudioDestinationNode wrapAudioDestinationNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioDestinationNodeWrappingImplementation._wrap(raw);
  }

  static AudioElement wrapAudioElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioElementWrappingImplementation._wrap(raw);
  }

  static AudioGain wrapAudioGain(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioGainWrappingImplementation._wrap(raw);
  }

  static AudioGainNode wrapAudioGainNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioGainNodeWrappingImplementation._wrap(raw);
  }

  static AudioListener wrapAudioListener(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioListenerWrappingImplementation._wrap(raw);
  }

  static AudioNode wrapAudioNode(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "AudioBufferSourceNode":
        return new AudioBufferSourceNodeWrappingImplementation._wrap(raw);
      case "AudioChannelMerger":
        return new AudioChannelMergerWrappingImplementation._wrap(raw);
      case "AudioChannelSplitter":
        return new AudioChannelSplitterWrappingImplementation._wrap(raw);
      case "AudioDestinationNode":
        return new AudioDestinationNodeWrappingImplementation._wrap(raw);
      case "AudioGainNode":
        return new AudioGainNodeWrappingImplementation._wrap(raw);
      case "AudioNode":
        return new AudioNodeWrappingImplementation._wrap(raw);
      case "AudioPannerNode":
        return new AudioPannerNodeWrappingImplementation._wrap(raw);
      case "AudioSourceNode":
        return new AudioSourceNodeWrappingImplementation._wrap(raw);
      case "BiquadFilterNode":
        return new BiquadFilterNodeWrappingImplementation._wrap(raw);
      case "ConvolverNode":
        return new ConvolverNodeWrappingImplementation._wrap(raw);
      case "DelayNode":
        return new DelayNodeWrappingImplementation._wrap(raw);
      case "DynamicsCompressorNode":
        return new DynamicsCompressorNodeWrappingImplementation._wrap(raw);
      case "HighPass2FilterNode":
        return new HighPass2FilterNodeWrappingImplementation._wrap(raw);
      case "JavaScriptAudioNode":
        return new JavaScriptAudioNodeWrappingImplementation._wrap(raw);
      case "LowPass2FilterNode":
        return new LowPass2FilterNodeWrappingImplementation._wrap(raw);
      case "MediaElementAudioSourceNode":
        return new MediaElementAudioSourceNodeWrappingImplementation._wrap(raw);
      case "RealtimeAnalyserNode":
        return new RealtimeAnalyserNodeWrappingImplementation._wrap(raw);
      case "WaveShaperNode":
        return new WaveShaperNodeWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static AudioPannerNode wrapAudioPannerNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioPannerNodeWrappingImplementation._wrap(raw);
  }

  static AudioParam wrapAudioParam(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "AudioGain":
        return new AudioGainWrappingImplementation._wrap(raw);
      case "AudioParam":
        return new AudioParamWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static AudioProcessingEvent wrapAudioProcessingEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioProcessingEventWrappingImplementation._wrap(raw);
  }

  static AudioSourceNode wrapAudioSourceNode(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "AudioBufferSourceNode":
        return new AudioBufferSourceNodeWrappingImplementation._wrap(raw);
      case "AudioSourceNode":
        return new AudioSourceNodeWrappingImplementation._wrap(raw);
      case "MediaElementAudioSourceNode":
        return new MediaElementAudioSourceNodeWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
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

  static BiquadFilterNode wrapBiquadFilterNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new BiquadFilterNodeWrappingImplementation._wrap(raw);
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
      case "SVGColor":
        return new SVGColorWrappingImplementation._wrap(raw);
      case "SVGPaint":
        return new SVGPaintWrappingImplementation._wrap(raw);
      case "WebKitCSSFilterValue":
        return new WebKitCSSFilterValueWrappingImplementation._wrap(raw);
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
      case "WebKitCSSFilterValue":
        return new WebKitCSSFilterValueWrappingImplementation._wrap(raw);
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

  static ClientRectList wrapClientRectList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ClientRectListWrappingImplementation._wrap(raw);
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

  static ConvolverNode wrapConvolverNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ConvolverNodeWrappingImplementation._wrap(raw);
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

  static DataTransferItemList wrapDataTransferItemList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DataTransferItemListWrappingImplementation._wrap(raw);
  }

  static DataView wrapDataView(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DataViewWrappingImplementation._wrap(raw);
  }

  // Skipped DatabaseCallback
  static DelayNode wrapDelayNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DelayNodeWrappingImplementation._wrap(raw);
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
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "HTMLDocument":
        return new DocumentWrappingImplementation._wrap(raw, raw.documentElement);
      case "SVGDocument":
        return new SVGDocumentWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static DocumentFragment wrapDocumentFragment(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DocumentFragmentWrappingImplementation._wrap(raw);
  }

  static DynamicsCompressorNode wrapDynamicsCompressorNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DynamicsCompressorNodeWrappingImplementation._wrap(raw);
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
      case "SVGAElement":
        return new SVGAElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphDefElement":
        return new SVGAltGlyphDefElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphElement":
        return new SVGAltGlyphElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphItemElement":
        return new SVGAltGlyphItemElementWrappingImplementation._wrap(raw);
      case "SVGAnimateColorElement":
        return new SVGAnimateColorElementWrappingImplementation._wrap(raw);
      case "SVGAnimateElement":
        return new SVGAnimateElementWrappingImplementation._wrap(raw);
      case "SVGAnimateMotionElement":
        return new SVGAnimateMotionElementWrappingImplementation._wrap(raw);
      case "SVGAnimateTransformElement":
        return new SVGAnimateTransformElementWrappingImplementation._wrap(raw);
      case "SVGAnimationElement":
        return new SVGAnimationElementWrappingImplementation._wrap(raw);
      case "SVGCircleElement":
        return new SVGCircleElementWrappingImplementation._wrap(raw);
      case "SVGClipPathElement":
        return new SVGClipPathElementWrappingImplementation._wrap(raw);
      case "SVGComponentTransferFunctionElement":
        return new SVGComponentTransferFunctionElementWrappingImplementation._wrap(raw);
      case "SVGCursorElement":
        return new SVGCursorElementWrappingImplementation._wrap(raw);
      case "SVGDefsElement":
        return new SVGDefsElementWrappingImplementation._wrap(raw);
      case "SVGDescElement":
        return new SVGDescElementWrappingImplementation._wrap(raw);
      case "SVGElement":
        return new SVGElementWrappingImplementation._wrap(raw);
      case "SVGEllipseElement":
        return new SVGEllipseElementWrappingImplementation._wrap(raw);
      case "SVGFEBlendElement":
        return new SVGFEBlendElementWrappingImplementation._wrap(raw);
      case "SVGFEColorMatrixElement":
        return new SVGFEColorMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEComponentTransferElement":
        return new SVGFEComponentTransferElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFECompositeElement*/
      case "SVGFEConvolveMatrixElement":
        return new SVGFEConvolveMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEDiffuseLightingElement":
        return new SVGFEDiffuseLightingElementWrappingImplementation._wrap(raw);
      case "SVGFEDisplacementMapElement":
        return new SVGFEDisplacementMapElementWrappingImplementation._wrap(raw);
      case "SVGFEDistantLightElement":
        return new SVGFEDistantLightElementWrappingImplementation._wrap(raw);
      case "SVGFEDropShadowElement":
        return new SVGFEDropShadowElementWrappingImplementation._wrap(raw);
      case "SVGFEFloodElement":
        return new SVGFEFloodElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncAElement":
        return new SVGFEFuncAElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncBElement":
        return new SVGFEFuncBElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncGElement":
        return new SVGFEFuncGElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncRElement":
        return new SVGFEFuncRElementWrappingImplementation._wrap(raw);
      case "SVGFEGaussianBlurElement":
        return new SVGFEGaussianBlurElementWrappingImplementation._wrap(raw);
      case "SVGFEImageElement":
        return new SVGFEImageElementWrappingImplementation._wrap(raw);
      case "SVGFEMergeElement":
        return new SVGFEMergeElementWrappingImplementation._wrap(raw);
      case "SVGFEMergeNodeElement":
        return new SVGFEMergeNodeElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFEMorphologyElement*/
      case "SVGFEOffsetElement":
        return new SVGFEOffsetElementWrappingImplementation._wrap(raw);
      case "SVGFEPointLightElement":
        return new SVGFEPointLightElementWrappingImplementation._wrap(raw);
      case "SVGFESpecularLightingElement":
        return new SVGFESpecularLightingElementWrappingImplementation._wrap(raw);
      case "SVGFESpotLightElement":
        return new SVGFESpotLightElementWrappingImplementation._wrap(raw);
      case "SVGFETileElement":
        return new SVGFETileElementWrappingImplementation._wrap(raw);
      case "SVGFETurbulenceElement":
        return new SVGFETurbulenceElementWrappingImplementation._wrap(raw);
      case "SVGFilterElement":
        return new SVGFilterElementWrappingImplementation._wrap(raw);
      case "SVGFontElement":
        return new SVGFontElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceElement":
        return new SVGFontFaceElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceFormatElement":
        return new SVGFontFaceFormatElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceNameElement":
        return new SVGFontFaceNameElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceSrcElement":
        return new SVGFontFaceSrcElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceUriElement":
        return new SVGFontFaceUriElementWrappingImplementation._wrap(raw);
      case "SVGForeignObjectElement":
        return new SVGForeignObjectElementWrappingImplementation._wrap(raw);
      case "SVGGElement":
        return new SVGGElementWrappingImplementation._wrap(raw);
      case "SVGGlyphElement":
        return new SVGGlyphElementWrappingImplementation._wrap(raw);
      case "SVGGlyphRefElement":
        return new SVGGlyphRefElementWrappingImplementation._wrap(raw);
      case "SVGGradientElement":
        return new SVGGradientElementWrappingImplementation._wrap(raw);
      case "SVGHKernElement":
        return new SVGHKernElementWrappingImplementation._wrap(raw);
      case "SVGImageElement":
        return new SVGImageElementWrappingImplementation._wrap(raw);
      case "SVGLineElement":
        return new SVGLineElementWrappingImplementation._wrap(raw);
      case "SVGLinearGradientElement":
        return new SVGLinearGradientElementWrappingImplementation._wrap(raw);
      case "SVGMPathElement":
        return new SVGMPathElementWrappingImplementation._wrap(raw);
      case "SVGMarkerElement":
        return new SVGMarkerElementWrappingImplementation._wrap(raw);
      case "SVGMaskElement":
        return new SVGMaskElementWrappingImplementation._wrap(raw);
      case "SVGMetadataElement":
        return new SVGMetadataElementWrappingImplementation._wrap(raw);
      case "SVGMissingGlyphElement":
        return new SVGMissingGlyphElementWrappingImplementation._wrap(raw);
      case "SVGPathElement":
        return new SVGPathElementWrappingImplementation._wrap(raw);
      case "SVGPatternElement":
        return new SVGPatternElementWrappingImplementation._wrap(raw);
      case "SVGPolygonElement":
        return new SVGPolygonElementWrappingImplementation._wrap(raw);
      case "SVGPolylineElement":
        return new SVGPolylineElementWrappingImplementation._wrap(raw);
      case "SVGRadialGradientElement":
        return new SVGRadialGradientElementWrappingImplementation._wrap(raw);
      case "SVGRectElement":
        return new SVGRectElementWrappingImplementation._wrap(raw);
      case "SVGSVGElement":
        return new SVGSVGElementWrappingImplementation._wrap(raw);
      case "SVGScriptElement":
        return new SVGScriptElementWrappingImplementation._wrap(raw);
      case "SVGSetElement":
        return new SVGSetElementWrappingImplementation._wrap(raw);
      case "SVGStopElement":
        return new SVGStopElementWrappingImplementation._wrap(raw);
      case "SVGStyleElement":
        return new SVGStyleElementWrappingImplementation._wrap(raw);
      case "SVGSwitchElement":
        return new SVGSwitchElementWrappingImplementation._wrap(raw);
      case "SVGSymbolElement":
        return new SVGSymbolElementWrappingImplementation._wrap(raw);
      case "SVGTRefElement":
        return new SVGTRefElementWrappingImplementation._wrap(raw);
      case "SVGTSpanElement":
        return new SVGTSpanElementWrappingImplementation._wrap(raw);
      case "SVGTextContentElement":
        return new SVGTextContentElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTextPathElement":
        return new SVGTextPathElementWrappingImplementation._wrap(raw);
      case "SVGTextPositioningElement":
        return new SVGTextPositioningElementWrappingImplementation._wrap(raw);
      case "SVGTitleElement":
        return new SVGTitleElementWrappingImplementation._wrap(raw);
      case "SVGUseElement":
        return new SVGUseElementWrappingImplementation._wrap(raw);
      case "SVGVKernElement":
        return new SVGVKernElementWrappingImplementation._wrap(raw);
      case "SVGViewElement":
        return new SVGViewElementWrappingImplementation._wrap(raw);
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

  static ElementTimeControl wrapElementTimeControl(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "ElementTimeControl":
        return new ElementTimeControlWrappingImplementation._wrap(raw);
      case "SVGAnimateColorElement":
        return new SVGAnimateColorElementWrappingImplementation._wrap(raw);
      case "SVGAnimateElement":
        return new SVGAnimateElementWrappingImplementation._wrap(raw);
      case "SVGAnimateMotionElement":
        return new SVGAnimateMotionElementWrappingImplementation._wrap(raw);
      case "SVGAnimateTransformElement":
        return new SVGAnimateTransformElementWrappingImplementation._wrap(raw);
      case "SVGAnimationElement":
        return new SVGAnimationElementWrappingImplementation._wrap(raw);
      case "SVGSetElement":
        return new SVGSetElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
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

  // Skipped EntriesCallback
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

  // Skipped EntryCallback
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

  // Skipped ErrorCallback
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
      case "AudioProcessingEvent":
        return new AudioProcessingEventWrappingImplementation._wrap(raw);
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
      case "OfflineAudioCompletionEvent":
        return new OfflineAudioCompletionEventWrappingImplementation._wrap(raw);
      case "OverflowEvent":
        return new OverflowEventWrappingImplementation._wrap(raw);
      case "PageTransitionEvent":
        return new PageTransitionEventWrappingImplementation._wrap(raw);
      case "PopStateEvent":
        return new PopStateEventWrappingImplementation._wrap(raw);
      case "ProgressEvent":
        return new ProgressEventWrappingImplementation._wrap(raw);
      case "SVGZoomEvent":
        return new SVGZoomEventWrappingImplementation._wrap(raw);
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
      case "SVGAElement":
        return new SVGAElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphDefElement":
        return new SVGAltGlyphDefElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphElement":
        return new SVGAltGlyphElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphItemElement":
        return new SVGAltGlyphItemElementWrappingImplementation._wrap(raw);
      case "SVGAnimateColorElement":
        return new SVGAnimateColorElementWrappingImplementation._wrap(raw);
      case "SVGAnimateElement":
        return new SVGAnimateElementWrappingImplementation._wrap(raw);
      case "SVGAnimateMotionElement":
        return new SVGAnimateMotionElementWrappingImplementation._wrap(raw);
      case "SVGAnimateTransformElement":
        return new SVGAnimateTransformElementWrappingImplementation._wrap(raw);
      case "SVGAnimationElement":
        return new SVGAnimationElementWrappingImplementation._wrap(raw);
      case "SVGCircleElement":
        return new SVGCircleElementWrappingImplementation._wrap(raw);
      case "SVGClipPathElement":
        return new SVGClipPathElementWrappingImplementation._wrap(raw);
      case "SVGComponentTransferFunctionElement":
        return new SVGComponentTransferFunctionElementWrappingImplementation._wrap(raw);
      case "SVGCursorElement":
        return new SVGCursorElementWrappingImplementation._wrap(raw);
      case "SVGDefsElement":
        return new SVGDefsElementWrappingImplementation._wrap(raw);
      case "SVGDescElement":
        return new SVGDescElementWrappingImplementation._wrap(raw);
      case "SVGDocument":
        return new SVGDocumentWrappingImplementation._wrap(raw);
      case "SVGElement":
        return new SVGElementWrappingImplementation._wrap(raw);
      case "SVGElementInstance":
        return new SVGElementInstanceWrappingImplementation._wrap(raw);
      case "SVGEllipseElement":
        return new SVGEllipseElementWrappingImplementation._wrap(raw);
      case "SVGFEBlendElement":
        return new SVGFEBlendElementWrappingImplementation._wrap(raw);
      case "SVGFEColorMatrixElement":
        return new SVGFEColorMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEComponentTransferElement":
        return new SVGFEComponentTransferElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFECompositeElement*/
      case "SVGFEConvolveMatrixElement":
        return new SVGFEConvolveMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEDiffuseLightingElement":
        return new SVGFEDiffuseLightingElementWrappingImplementation._wrap(raw);
      case "SVGFEDisplacementMapElement":
        return new SVGFEDisplacementMapElementWrappingImplementation._wrap(raw);
      case "SVGFEDistantLightElement":
        return new SVGFEDistantLightElementWrappingImplementation._wrap(raw);
      case "SVGFEDropShadowElement":
        return new SVGFEDropShadowElementWrappingImplementation._wrap(raw);
      case "SVGFEFloodElement":
        return new SVGFEFloodElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncAElement":
        return new SVGFEFuncAElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncBElement":
        return new SVGFEFuncBElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncGElement":
        return new SVGFEFuncGElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncRElement":
        return new SVGFEFuncRElementWrappingImplementation._wrap(raw);
      case "SVGFEGaussianBlurElement":
        return new SVGFEGaussianBlurElementWrappingImplementation._wrap(raw);
      case "SVGFEImageElement":
        return new SVGFEImageElementWrappingImplementation._wrap(raw);
      case "SVGFEMergeElement":
        return new SVGFEMergeElementWrappingImplementation._wrap(raw);
      case "SVGFEMergeNodeElement":
        return new SVGFEMergeNodeElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFEMorphologyElement*/
      case "SVGFEOffsetElement":
        return new SVGFEOffsetElementWrappingImplementation._wrap(raw);
      case "SVGFEPointLightElement":
        return new SVGFEPointLightElementWrappingImplementation._wrap(raw);
      case "SVGFESpecularLightingElement":
        return new SVGFESpecularLightingElementWrappingImplementation._wrap(raw);
      case "SVGFESpotLightElement":
        return new SVGFESpotLightElementWrappingImplementation._wrap(raw);
      case "SVGFETileElement":
        return new SVGFETileElementWrappingImplementation._wrap(raw);
      case "SVGFETurbulenceElement":
        return new SVGFETurbulenceElementWrappingImplementation._wrap(raw);
      case "SVGFilterElement":
        return new SVGFilterElementWrappingImplementation._wrap(raw);
      case "SVGFontElement":
        return new SVGFontElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceElement":
        return new SVGFontFaceElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceFormatElement":
        return new SVGFontFaceFormatElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceNameElement":
        return new SVGFontFaceNameElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceSrcElement":
        return new SVGFontFaceSrcElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceUriElement":
        return new SVGFontFaceUriElementWrappingImplementation._wrap(raw);
      case "SVGForeignObjectElement":
        return new SVGForeignObjectElementWrappingImplementation._wrap(raw);
      case "SVGGElement":
        return new SVGGElementWrappingImplementation._wrap(raw);
      case "SVGGlyphElement":
        return new SVGGlyphElementWrappingImplementation._wrap(raw);
      case "SVGGlyphRefElement":
        return new SVGGlyphRefElementWrappingImplementation._wrap(raw);
      case "SVGGradientElement":
        return new SVGGradientElementWrappingImplementation._wrap(raw);
      case "SVGHKernElement":
        return new SVGHKernElementWrappingImplementation._wrap(raw);
      case "SVGImageElement":
        return new SVGImageElementWrappingImplementation._wrap(raw);
      case "SVGLineElement":
        return new SVGLineElementWrappingImplementation._wrap(raw);
      case "SVGLinearGradientElement":
        return new SVGLinearGradientElementWrappingImplementation._wrap(raw);
      case "SVGMPathElement":
        return new SVGMPathElementWrappingImplementation._wrap(raw);
      case "SVGMarkerElement":
        return new SVGMarkerElementWrappingImplementation._wrap(raw);
      case "SVGMaskElement":
        return new SVGMaskElementWrappingImplementation._wrap(raw);
      case "SVGMetadataElement":
        return new SVGMetadataElementWrappingImplementation._wrap(raw);
      case "SVGMissingGlyphElement":
        return new SVGMissingGlyphElementWrappingImplementation._wrap(raw);
      case "SVGPathElement":
        return new SVGPathElementWrappingImplementation._wrap(raw);
      case "SVGPatternElement":
        return new SVGPatternElementWrappingImplementation._wrap(raw);
      case "SVGPolygonElement":
        return new SVGPolygonElementWrappingImplementation._wrap(raw);
      case "SVGPolylineElement":
        return new SVGPolylineElementWrappingImplementation._wrap(raw);
      case "SVGRadialGradientElement":
        return new SVGRadialGradientElementWrappingImplementation._wrap(raw);
      case "SVGRectElement":
        return new SVGRectElementWrappingImplementation._wrap(raw);
      case "SVGSVGElement":
        return new SVGSVGElementWrappingImplementation._wrap(raw);
      case "SVGScriptElement":
        return new SVGScriptElementWrappingImplementation._wrap(raw);
      case "SVGSetElement":
        return new SVGSetElementWrappingImplementation._wrap(raw);
      case "SVGStopElement":
        return new SVGStopElementWrappingImplementation._wrap(raw);
      case "SVGStyleElement":
        return new SVGStyleElementWrappingImplementation._wrap(raw);
      case "SVGSwitchElement":
        return new SVGSwitchElementWrappingImplementation._wrap(raw);
      case "SVGSymbolElement":
        return new SVGSymbolElementWrappingImplementation._wrap(raw);
      case "SVGTRefElement":
        return new SVGTRefElementWrappingImplementation._wrap(raw);
      case "SVGTSpanElement":
        return new SVGTSpanElementWrappingImplementation._wrap(raw);
      case "SVGTextContentElement":
        return new SVGTextContentElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTextPathElement":
        return new SVGTextPathElementWrappingImplementation._wrap(raw);
      case "SVGTextPositioningElement":
        return new SVGTextPositioningElementWrappingImplementation._wrap(raw);
      case "SVGTitleElement":
        return new SVGTitleElementWrappingImplementation._wrap(raw);
      case "SVGUseElement":
        return new SVGUseElementWrappingImplementation._wrap(raw);
      case "SVGVKernElement":
        return new SVGVKernElementWrappingImplementation._wrap(raw);
      case "SVGViewElement":
        return new SVGViewElementWrappingImplementation._wrap(raw);
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

  // Skipped FileCallback
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

  // Skipped FileSystemCallback
  static FileWriter wrapFileWriter(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileWriterWrappingImplementation._wrap(raw);
  }

  // Skipped FileWriterCallback
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

  static HighPass2FilterNode wrapHighPass2FilterNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new HighPass2FilterNodeWrappingImplementation._wrap(raw);
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

  static JavaScriptAudioNode wrapJavaScriptAudioNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new JavaScriptAudioNodeWrappingImplementation._wrap(raw);
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

  static Location wrapLocation(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new LocationWrappingImplementation._wrap(raw);
  }

  static LoseContext wrapLoseContext(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new LoseContextWrappingImplementation._wrap(raw);
  }

  static LowPass2FilterNode wrapLowPass2FilterNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new LowPass2FilterNodeWrappingImplementation._wrap(raw);
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

  static MediaElementAudioSourceNode wrapMediaElementAudioSourceNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MediaElementAudioSourceNodeWrappingImplementation._wrap(raw);
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

  // Skipped MetadataCallback
  static MeterElement wrapMeterElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MeterElementWrappingImplementation._wrap(raw);
  }

  static ModElement wrapModElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ModElementWrappingImplementation._wrap(raw);
  }

  static MouseEvent wrapMouseEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MouseEventWrappingImplementation._wrap(raw);
  }

  static MutationCallback wrapMutationCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MutationCallbackWrappingImplementation._wrap(raw);
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

  // Skipped NavigatorUserMediaErrorCallback
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
      case "SVGAElement":
        return new SVGAElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphDefElement":
        return new SVGAltGlyphDefElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphElement":
        return new SVGAltGlyphElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphItemElement":
        return new SVGAltGlyphItemElementWrappingImplementation._wrap(raw);
      case "SVGAnimateColorElement":
        return new SVGAnimateColorElementWrappingImplementation._wrap(raw);
      case "SVGAnimateElement":
        return new SVGAnimateElementWrappingImplementation._wrap(raw);
      case "SVGAnimateMotionElement":
        return new SVGAnimateMotionElementWrappingImplementation._wrap(raw);
      case "SVGAnimateTransformElement":
        return new SVGAnimateTransformElementWrappingImplementation._wrap(raw);
      case "SVGAnimationElement":
        return new SVGAnimationElementWrappingImplementation._wrap(raw);
      case "SVGCircleElement":
        return new SVGCircleElementWrappingImplementation._wrap(raw);
      case "SVGClipPathElement":
        return new SVGClipPathElementWrappingImplementation._wrap(raw);
      case "SVGComponentTransferFunctionElement":
        return new SVGComponentTransferFunctionElementWrappingImplementation._wrap(raw);
      case "SVGCursorElement":
        return new SVGCursorElementWrappingImplementation._wrap(raw);
      case "SVGDefsElement":
        return new SVGDefsElementWrappingImplementation._wrap(raw);
      case "SVGDescElement":
        return new SVGDescElementWrappingImplementation._wrap(raw);
      case "SVGDocument":
        return new SVGDocumentWrappingImplementation._wrap(raw);
      case "SVGElement":
        return new SVGElementWrappingImplementation._wrap(raw);
      case "SVGEllipseElement":
        return new SVGEllipseElementWrappingImplementation._wrap(raw);
      case "SVGFEBlendElement":
        return new SVGFEBlendElementWrappingImplementation._wrap(raw);
      case "SVGFEColorMatrixElement":
        return new SVGFEColorMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEComponentTransferElement":
        return new SVGFEComponentTransferElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFECompositeElement*/
      case "SVGFEConvolveMatrixElement":
        return new SVGFEConvolveMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEDiffuseLightingElement":
        return new SVGFEDiffuseLightingElementWrappingImplementation._wrap(raw);
      case "SVGFEDisplacementMapElement":
        return new SVGFEDisplacementMapElementWrappingImplementation._wrap(raw);
      case "SVGFEDistantLightElement":
        return new SVGFEDistantLightElementWrappingImplementation._wrap(raw);
      case "SVGFEDropShadowElement":
        return new SVGFEDropShadowElementWrappingImplementation._wrap(raw);
      case "SVGFEFloodElement":
        return new SVGFEFloodElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncAElement":
        return new SVGFEFuncAElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncBElement":
        return new SVGFEFuncBElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncGElement":
        return new SVGFEFuncGElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncRElement":
        return new SVGFEFuncRElementWrappingImplementation._wrap(raw);
      case "SVGFEGaussianBlurElement":
        return new SVGFEGaussianBlurElementWrappingImplementation._wrap(raw);
      case "SVGFEImageElement":
        return new SVGFEImageElementWrappingImplementation._wrap(raw);
      case "SVGFEMergeElement":
        return new SVGFEMergeElementWrappingImplementation._wrap(raw);
      case "SVGFEMergeNodeElement":
        return new SVGFEMergeNodeElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFEMorphologyElement*/
      case "SVGFEOffsetElement":
        return new SVGFEOffsetElementWrappingImplementation._wrap(raw);
      case "SVGFEPointLightElement":
        return new SVGFEPointLightElementWrappingImplementation._wrap(raw);
      case "SVGFESpecularLightingElement":
        return new SVGFESpecularLightingElementWrappingImplementation._wrap(raw);
      case "SVGFESpotLightElement":
        return new SVGFESpotLightElementWrappingImplementation._wrap(raw);
      case "SVGFETileElement":
        return new SVGFETileElementWrappingImplementation._wrap(raw);
      case "SVGFETurbulenceElement":
        return new SVGFETurbulenceElementWrappingImplementation._wrap(raw);
      case "SVGFilterElement":
        return new SVGFilterElementWrappingImplementation._wrap(raw);
      case "SVGFontElement":
        return new SVGFontElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceElement":
        return new SVGFontFaceElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceFormatElement":
        return new SVGFontFaceFormatElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceNameElement":
        return new SVGFontFaceNameElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceSrcElement":
        return new SVGFontFaceSrcElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceUriElement":
        return new SVGFontFaceUriElementWrappingImplementation._wrap(raw);
      case "SVGForeignObjectElement":
        return new SVGForeignObjectElementWrappingImplementation._wrap(raw);
      case "SVGGElement":
        return new SVGGElementWrappingImplementation._wrap(raw);
      case "SVGGlyphElement":
        return new SVGGlyphElementWrappingImplementation._wrap(raw);
      case "SVGGlyphRefElement":
        return new SVGGlyphRefElementWrappingImplementation._wrap(raw);
      case "SVGGradientElement":
        return new SVGGradientElementWrappingImplementation._wrap(raw);
      case "SVGHKernElement":
        return new SVGHKernElementWrappingImplementation._wrap(raw);
      case "SVGImageElement":
        return new SVGImageElementWrappingImplementation._wrap(raw);
      case "SVGLineElement":
        return new SVGLineElementWrappingImplementation._wrap(raw);
      case "SVGLinearGradientElement":
        return new SVGLinearGradientElementWrappingImplementation._wrap(raw);
      case "SVGMPathElement":
        return new SVGMPathElementWrappingImplementation._wrap(raw);
      case "SVGMarkerElement":
        return new SVGMarkerElementWrappingImplementation._wrap(raw);
      case "SVGMaskElement":
        return new SVGMaskElementWrappingImplementation._wrap(raw);
      case "SVGMetadataElement":
        return new SVGMetadataElementWrappingImplementation._wrap(raw);
      case "SVGMissingGlyphElement":
        return new SVGMissingGlyphElementWrappingImplementation._wrap(raw);
      case "SVGPathElement":
        return new SVGPathElementWrappingImplementation._wrap(raw);
      case "SVGPatternElement":
        return new SVGPatternElementWrappingImplementation._wrap(raw);
      case "SVGPolygonElement":
        return new SVGPolygonElementWrappingImplementation._wrap(raw);
      case "SVGPolylineElement":
        return new SVGPolylineElementWrappingImplementation._wrap(raw);
      case "SVGRadialGradientElement":
        return new SVGRadialGradientElementWrappingImplementation._wrap(raw);
      case "SVGRectElement":
        return new SVGRectElementWrappingImplementation._wrap(raw);
      case "SVGSVGElement":
        return new SVGSVGElementWrappingImplementation._wrap(raw);
      case "SVGScriptElement":
        return new SVGScriptElementWrappingImplementation._wrap(raw);
      case "SVGSetElement":
        return new SVGSetElementWrappingImplementation._wrap(raw);
      case "SVGStopElement":
        return new SVGStopElementWrappingImplementation._wrap(raw);
      case "SVGStyleElement":
        return new SVGStyleElementWrappingImplementation._wrap(raw);
      case "SVGSwitchElement":
        return new SVGSwitchElementWrappingImplementation._wrap(raw);
      case "SVGSymbolElement":
        return new SVGSymbolElementWrappingImplementation._wrap(raw);
      case "SVGTRefElement":
        return new SVGTRefElementWrappingImplementation._wrap(raw);
      case "SVGTSpanElement":
        return new SVGTSpanElementWrappingImplementation._wrap(raw);
      case "SVGTextContentElement":
        return new SVGTextContentElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTextPathElement":
        return new SVGTextPathElementWrappingImplementation._wrap(raw);
      case "SVGTextPositioningElement":
        return new SVGTextPositioningElementWrappingImplementation._wrap(raw);
      case "SVGTitleElement":
        return new SVGTitleElementWrappingImplementation._wrap(raw);
      case "SVGUseElement":
        return new SVGUseElementWrappingImplementation._wrap(raw);
      case "SVGVKernElement":
        return new SVGVKernElementWrappingImplementation._wrap(raw);
      case "SVGViewElement":
        return new SVGViewElementWrappingImplementation._wrap(raw);
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

  static OfflineAudioCompletionEvent wrapOfflineAudioCompletionEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OfflineAudioCompletionEventWrappingImplementation._wrap(raw);
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

  // Skipped PositionCallback
  static PositionError wrapPositionError(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new PositionErrorWrappingImplementation._wrap(raw);
  }

  // Skipped PositionErrorCallback
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

  static RealtimeAnalyserNode wrapRealtimeAnalyserNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new RealtimeAnalyserNodeWrappingImplementation._wrap(raw);
  }

  static Rect wrapRect(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new RectWrappingImplementation._wrap(raw);
  }

  // Skipped RequestAnimationFrameCallback
  // Skipped SQLStatementCallback
  // Skipped SQLStatementErrorCallback
  // Skipped SQLTransactionCallback
  // Skipped SQLTransactionErrorCallback
  // Skipped SQLTransactionSyncCallback
  static SVGAElement wrapSVGAElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAElementWrappingImplementation._wrap(raw);
  }

  static SVGAltGlyphDefElement wrapSVGAltGlyphDefElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAltGlyphDefElementWrappingImplementation._wrap(raw);
  }

  static SVGAltGlyphElement wrapSVGAltGlyphElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAltGlyphElementWrappingImplementation._wrap(raw);
  }

  static SVGAltGlyphItemElement wrapSVGAltGlyphItemElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAltGlyphItemElementWrappingImplementation._wrap(raw);
  }

  static SVGAngle wrapSVGAngle(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAngleWrappingImplementation._wrap(raw);
  }

  static SVGAnimateColorElement wrapSVGAnimateColorElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimateColorElementWrappingImplementation._wrap(raw);
  }

  static SVGAnimateElement wrapSVGAnimateElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimateElementWrappingImplementation._wrap(raw);
  }

  static SVGAnimateMotionElement wrapSVGAnimateMotionElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimateMotionElementWrappingImplementation._wrap(raw);
  }

  static SVGAnimateTransformElement wrapSVGAnimateTransformElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimateTransformElementWrappingImplementation._wrap(raw);
  }

  static SVGAnimatedAngle wrapSVGAnimatedAngle(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimatedAngleWrappingImplementation._wrap(raw);
  }

  static SVGAnimatedBoolean wrapSVGAnimatedBoolean(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimatedBooleanWrappingImplementation._wrap(raw);
  }

  static SVGAnimatedEnumeration wrapSVGAnimatedEnumeration(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimatedEnumerationWrappingImplementation._wrap(raw);
  }

  static SVGAnimatedInteger wrapSVGAnimatedInteger(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimatedIntegerWrappingImplementation._wrap(raw);
  }

  static SVGAnimatedLength wrapSVGAnimatedLength(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimatedLengthWrappingImplementation._wrap(raw);
  }

  static SVGAnimatedLengthList wrapSVGAnimatedLengthList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimatedLengthListWrappingImplementation._wrap(raw);
  }

  static SVGAnimatedNumber wrapSVGAnimatedNumber(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimatedNumberWrappingImplementation._wrap(raw);
  }

  static SVGAnimatedNumberList wrapSVGAnimatedNumberList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimatedNumberListWrappingImplementation._wrap(raw);
  }

  static SVGAnimatedPreserveAspectRatio wrapSVGAnimatedPreserveAspectRatio(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimatedPreserveAspectRatioWrappingImplementation._wrap(raw);
  }

  static SVGAnimatedRect wrapSVGAnimatedRect(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimatedRectWrappingImplementation._wrap(raw);
  }

  static SVGAnimatedString wrapSVGAnimatedString(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimatedStringWrappingImplementation._wrap(raw);
  }

  static SVGAnimatedTransformList wrapSVGAnimatedTransformList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimatedTransformListWrappingImplementation._wrap(raw);
  }

  static SVGAnimationElement wrapSVGAnimationElement(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGAnimateColorElement":
        return new SVGAnimateColorElementWrappingImplementation._wrap(raw);
      case "SVGAnimateElement":
        return new SVGAnimateElementWrappingImplementation._wrap(raw);
      case "SVGAnimateMotionElement":
        return new SVGAnimateMotionElementWrappingImplementation._wrap(raw);
      case "SVGAnimateTransformElement":
        return new SVGAnimateTransformElementWrappingImplementation._wrap(raw);
      case "SVGAnimationElement":
        return new SVGAnimationElementWrappingImplementation._wrap(raw);
      case "SVGSetElement":
        return new SVGSetElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGCircleElement wrapSVGCircleElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGCircleElementWrappingImplementation._wrap(raw);
  }

  static SVGClipPathElement wrapSVGClipPathElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGClipPathElementWrappingImplementation._wrap(raw);
  }

  static SVGColor wrapSVGColor(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGColor":
        return new SVGColorWrappingImplementation._wrap(raw);
      case "SVGPaint":
        return new SVGPaintWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGComponentTransferFunctionElement wrapSVGComponentTransferFunctionElement(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGComponentTransferFunctionElement":
        return new SVGComponentTransferFunctionElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncAElement":
        return new SVGFEFuncAElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncBElement":
        return new SVGFEFuncBElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncGElement":
        return new SVGFEFuncGElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncRElement":
        return new SVGFEFuncRElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGCursorElement wrapSVGCursorElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGCursorElementWrappingImplementation._wrap(raw);
  }

  static SVGDefsElement wrapSVGDefsElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGDefsElementWrappingImplementation._wrap(raw);
  }

  static SVGDescElement wrapSVGDescElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGDescElementWrappingImplementation._wrap(raw);
  }

  static SVGDocument wrapSVGDocument(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGDocumentWrappingImplementation._wrap(raw);
  }

  static SVGElement wrapSVGElement(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGAElement":
        return new SVGAElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphDefElement":
        return new SVGAltGlyphDefElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphElement":
        return new SVGAltGlyphElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphItemElement":
        return new SVGAltGlyphItemElementWrappingImplementation._wrap(raw);
      case "SVGAnimateColorElement":
        return new SVGAnimateColorElementWrappingImplementation._wrap(raw);
      case "SVGAnimateElement":
        return new SVGAnimateElementWrappingImplementation._wrap(raw);
      case "SVGAnimateMotionElement":
        return new SVGAnimateMotionElementWrappingImplementation._wrap(raw);
      case "SVGAnimateTransformElement":
        return new SVGAnimateTransformElementWrappingImplementation._wrap(raw);
      case "SVGAnimationElement":
        return new SVGAnimationElementWrappingImplementation._wrap(raw);
      case "SVGCircleElement":
        return new SVGCircleElementWrappingImplementation._wrap(raw);
      case "SVGClipPathElement":
        return new SVGClipPathElementWrappingImplementation._wrap(raw);
      case "SVGComponentTransferFunctionElement":
        return new SVGComponentTransferFunctionElementWrappingImplementation._wrap(raw);
      case "SVGCursorElement":
        return new SVGCursorElementWrappingImplementation._wrap(raw);
      case "SVGDefsElement":
        return new SVGDefsElementWrappingImplementation._wrap(raw);
      case "SVGDescElement":
        return new SVGDescElementWrappingImplementation._wrap(raw);
      case "SVGElement":
        return new SVGElementWrappingImplementation._wrap(raw);
      case "SVGEllipseElement":
        return new SVGEllipseElementWrappingImplementation._wrap(raw);
      case "SVGFEBlendElement":
        return new SVGFEBlendElementWrappingImplementation._wrap(raw);
      case "SVGFEColorMatrixElement":
        return new SVGFEColorMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEComponentTransferElement":
        return new SVGFEComponentTransferElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFECompositeElement*/
      case "SVGFEConvolveMatrixElement":
        return new SVGFEConvolveMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEDiffuseLightingElement":
        return new SVGFEDiffuseLightingElementWrappingImplementation._wrap(raw);
      case "SVGFEDisplacementMapElement":
        return new SVGFEDisplacementMapElementWrappingImplementation._wrap(raw);
      case "SVGFEDistantLightElement":
        return new SVGFEDistantLightElementWrappingImplementation._wrap(raw);
      case "SVGFEDropShadowElement":
        return new SVGFEDropShadowElementWrappingImplementation._wrap(raw);
      case "SVGFEFloodElement":
        return new SVGFEFloodElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncAElement":
        return new SVGFEFuncAElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncBElement":
        return new SVGFEFuncBElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncGElement":
        return new SVGFEFuncGElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncRElement":
        return new SVGFEFuncRElementWrappingImplementation._wrap(raw);
      case "SVGFEGaussianBlurElement":
        return new SVGFEGaussianBlurElementWrappingImplementation._wrap(raw);
      case "SVGFEImageElement":
        return new SVGFEImageElementWrappingImplementation._wrap(raw);
      case "SVGFEMergeElement":
        return new SVGFEMergeElementWrappingImplementation._wrap(raw);
      case "SVGFEMergeNodeElement":
        return new SVGFEMergeNodeElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFEMorphologyElement*/
      case "SVGFEOffsetElement":
        return new SVGFEOffsetElementWrappingImplementation._wrap(raw);
      case "SVGFEPointLightElement":
        return new SVGFEPointLightElementWrappingImplementation._wrap(raw);
      case "SVGFESpecularLightingElement":
        return new SVGFESpecularLightingElementWrappingImplementation._wrap(raw);
      case "SVGFESpotLightElement":
        return new SVGFESpotLightElementWrappingImplementation._wrap(raw);
      case "SVGFETileElement":
        return new SVGFETileElementWrappingImplementation._wrap(raw);
      case "SVGFETurbulenceElement":
        return new SVGFETurbulenceElementWrappingImplementation._wrap(raw);
      case "SVGFilterElement":
        return new SVGFilterElementWrappingImplementation._wrap(raw);
      case "SVGFontElement":
        return new SVGFontElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceElement":
        return new SVGFontFaceElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceFormatElement":
        return new SVGFontFaceFormatElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceNameElement":
        return new SVGFontFaceNameElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceSrcElement":
        return new SVGFontFaceSrcElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceUriElement":
        return new SVGFontFaceUriElementWrappingImplementation._wrap(raw);
      case "SVGForeignObjectElement":
        return new SVGForeignObjectElementWrappingImplementation._wrap(raw);
      case "SVGGElement":
        return new SVGGElementWrappingImplementation._wrap(raw);
      case "SVGGlyphElement":
        return new SVGGlyphElementWrappingImplementation._wrap(raw);
      case "SVGGlyphRefElement":
        return new SVGGlyphRefElementWrappingImplementation._wrap(raw);
      case "SVGGradientElement":
        return new SVGGradientElementWrappingImplementation._wrap(raw);
      case "SVGHKernElement":
        return new SVGHKernElementWrappingImplementation._wrap(raw);
      case "SVGImageElement":
        return new SVGImageElementWrappingImplementation._wrap(raw);
      case "SVGLineElement":
        return new SVGLineElementWrappingImplementation._wrap(raw);
      case "SVGLinearGradientElement":
        return new SVGLinearGradientElementWrappingImplementation._wrap(raw);
      case "SVGMPathElement":
        return new SVGMPathElementWrappingImplementation._wrap(raw);
      case "SVGMarkerElement":
        return new SVGMarkerElementWrappingImplementation._wrap(raw);
      case "SVGMaskElement":
        return new SVGMaskElementWrappingImplementation._wrap(raw);
      case "SVGMetadataElement":
        return new SVGMetadataElementWrappingImplementation._wrap(raw);
      case "SVGMissingGlyphElement":
        return new SVGMissingGlyphElementWrappingImplementation._wrap(raw);
      case "SVGPathElement":
        return new SVGPathElementWrappingImplementation._wrap(raw);
      case "SVGPatternElement":
        return new SVGPatternElementWrappingImplementation._wrap(raw);
      case "SVGPolygonElement":
        return new SVGPolygonElementWrappingImplementation._wrap(raw);
      case "SVGPolylineElement":
        return new SVGPolylineElementWrappingImplementation._wrap(raw);
      case "SVGRadialGradientElement":
        return new SVGRadialGradientElementWrappingImplementation._wrap(raw);
      case "SVGRectElement":
        return new SVGRectElementWrappingImplementation._wrap(raw);
      case "SVGSVGElement":
        return new SVGSVGElementWrappingImplementation._wrap(raw);
      case "SVGScriptElement":
        return new SVGScriptElementWrappingImplementation._wrap(raw);
      case "SVGSetElement":
        return new SVGSetElementWrappingImplementation._wrap(raw);
      case "SVGStopElement":
        return new SVGStopElementWrappingImplementation._wrap(raw);
      case "SVGStyleElement":
        return new SVGStyleElementWrappingImplementation._wrap(raw);
      case "SVGSwitchElement":
        return new SVGSwitchElementWrappingImplementation._wrap(raw);
      case "SVGSymbolElement":
        return new SVGSymbolElementWrappingImplementation._wrap(raw);
      case "SVGTRefElement":
        return new SVGTRefElementWrappingImplementation._wrap(raw);
      case "SVGTSpanElement":
        return new SVGTSpanElementWrappingImplementation._wrap(raw);
      case "SVGTextContentElement":
        return new SVGTextContentElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTextPathElement":
        return new SVGTextPathElementWrappingImplementation._wrap(raw);
      case "SVGTextPositioningElement":
        return new SVGTextPositioningElementWrappingImplementation._wrap(raw);
      case "SVGTitleElement":
        return new SVGTitleElementWrappingImplementation._wrap(raw);
      case "SVGUseElement":
        return new SVGUseElementWrappingImplementation._wrap(raw);
      case "SVGVKernElement":
        return new SVGVKernElementWrappingImplementation._wrap(raw);
      case "SVGViewElement":
        return new SVGViewElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGElementInstance wrapSVGElementInstance(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGElementInstanceWrappingImplementation._wrap(raw);
  }

  static SVGElementInstanceList wrapSVGElementInstanceList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGElementInstanceListWrappingImplementation._wrap(raw);
  }

  static SVGEllipseElement wrapSVGEllipseElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGEllipseElementWrappingImplementation._wrap(raw);
  }

  static SVGException wrapSVGException(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGExceptionWrappingImplementation._wrap(raw);
  }

  static SVGExternalResourcesRequired wrapSVGExternalResourcesRequired(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGAElement":
        return new SVGAElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphElement":
        return new SVGAltGlyphElementWrappingImplementation._wrap(raw);
      case "SVGAnimateColorElement":
        return new SVGAnimateColorElementWrappingImplementation._wrap(raw);
      case "SVGAnimateElement":
        return new SVGAnimateElementWrappingImplementation._wrap(raw);
      case "SVGAnimateMotionElement":
        return new SVGAnimateMotionElementWrappingImplementation._wrap(raw);
      case "SVGAnimateTransformElement":
        return new SVGAnimateTransformElementWrappingImplementation._wrap(raw);
      case "SVGAnimationElement":
        return new SVGAnimationElementWrappingImplementation._wrap(raw);
      case "SVGCircleElement":
        return new SVGCircleElementWrappingImplementation._wrap(raw);
      case "SVGClipPathElement":
        return new SVGClipPathElementWrappingImplementation._wrap(raw);
      case "SVGCursorElement":
        return new SVGCursorElementWrappingImplementation._wrap(raw);
      case "SVGDefsElement":
        return new SVGDefsElementWrappingImplementation._wrap(raw);
      case "SVGEllipseElement":
        return new SVGEllipseElementWrappingImplementation._wrap(raw);
      case "SVGExternalResourcesRequired":
        return new SVGExternalResourcesRequiredWrappingImplementation._wrap(raw);
      case "SVGFEImageElement":
        return new SVGFEImageElementWrappingImplementation._wrap(raw);
      case "SVGFilterElement":
        return new SVGFilterElementWrappingImplementation._wrap(raw);
      case "SVGForeignObjectElement":
        return new SVGForeignObjectElementWrappingImplementation._wrap(raw);
      case "SVGGElement":
        return new SVGGElementWrappingImplementation._wrap(raw);
      case "SVGGradientElement":
        return new SVGGradientElementWrappingImplementation._wrap(raw);
      case "SVGImageElement":
        return new SVGImageElementWrappingImplementation._wrap(raw);
      case "SVGLineElement":
        return new SVGLineElementWrappingImplementation._wrap(raw);
      case "SVGLinearGradientElement":
        return new SVGLinearGradientElementWrappingImplementation._wrap(raw);
      case "SVGMPathElement":
        return new SVGMPathElementWrappingImplementation._wrap(raw);
      case "SVGMarkerElement":
        return new SVGMarkerElementWrappingImplementation._wrap(raw);
      case "SVGMaskElement":
        return new SVGMaskElementWrappingImplementation._wrap(raw);
      case "SVGPathElement":
        return new SVGPathElementWrappingImplementation._wrap(raw);
      case "SVGPatternElement":
        return new SVGPatternElementWrappingImplementation._wrap(raw);
      case "SVGPolygonElement":
        return new SVGPolygonElementWrappingImplementation._wrap(raw);
      case "SVGPolylineElement":
        return new SVGPolylineElementWrappingImplementation._wrap(raw);
      case "SVGRadialGradientElement":
        return new SVGRadialGradientElementWrappingImplementation._wrap(raw);
      case "SVGRectElement":
        return new SVGRectElementWrappingImplementation._wrap(raw);
      case "SVGSVGElement":
        return new SVGSVGElementWrappingImplementation._wrap(raw);
      case "SVGScriptElement":
        return new SVGScriptElementWrappingImplementation._wrap(raw);
      case "SVGSetElement":
        return new SVGSetElementWrappingImplementation._wrap(raw);
      case "SVGSwitchElement":
        return new SVGSwitchElementWrappingImplementation._wrap(raw);
      case "SVGSymbolElement":
        return new SVGSymbolElementWrappingImplementation._wrap(raw);
      case "SVGTRefElement":
        return new SVGTRefElementWrappingImplementation._wrap(raw);
      case "SVGTSpanElement":
        return new SVGTSpanElementWrappingImplementation._wrap(raw);
      case "SVGTextContentElement":
        return new SVGTextContentElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTextPathElement":
        return new SVGTextPathElementWrappingImplementation._wrap(raw);
      case "SVGTextPositioningElement":
        return new SVGTextPositioningElementWrappingImplementation._wrap(raw);
      case "SVGUseElement":
        return new SVGUseElementWrappingImplementation._wrap(raw);
      case "SVGViewElement":
        return new SVGViewElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGFEBlendElement wrapSVGFEBlendElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEBlendElementWrappingImplementation._wrap(raw);
  }

  static SVGFEColorMatrixElement wrapSVGFEColorMatrixElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEColorMatrixElementWrappingImplementation._wrap(raw);
  }

  static SVGFEComponentTransferElement wrapSVGFEComponentTransferElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEComponentTransferElementWrappingImplementation._wrap(raw);
  }

  static SVGFEConvolveMatrixElement wrapSVGFEConvolveMatrixElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEConvolveMatrixElementWrappingImplementation._wrap(raw);
  }

  static SVGFEDiffuseLightingElement wrapSVGFEDiffuseLightingElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEDiffuseLightingElementWrappingImplementation._wrap(raw);
  }

  static SVGFEDisplacementMapElement wrapSVGFEDisplacementMapElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEDisplacementMapElementWrappingImplementation._wrap(raw);
  }

  static SVGFEDistantLightElement wrapSVGFEDistantLightElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEDistantLightElementWrappingImplementation._wrap(raw);
  }

  static SVGFEDropShadowElement wrapSVGFEDropShadowElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEDropShadowElementWrappingImplementation._wrap(raw);
  }

  static SVGFEFloodElement wrapSVGFEFloodElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEFloodElementWrappingImplementation._wrap(raw);
  }

  static SVGFEFuncAElement wrapSVGFEFuncAElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEFuncAElementWrappingImplementation._wrap(raw);
  }

  static SVGFEFuncBElement wrapSVGFEFuncBElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEFuncBElementWrappingImplementation._wrap(raw);
  }

  static SVGFEFuncGElement wrapSVGFEFuncGElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEFuncGElementWrappingImplementation._wrap(raw);
  }

  static SVGFEFuncRElement wrapSVGFEFuncRElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEFuncRElementWrappingImplementation._wrap(raw);
  }

  static SVGFEGaussianBlurElement wrapSVGFEGaussianBlurElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEGaussianBlurElementWrappingImplementation._wrap(raw);
  }

  static SVGFEImageElement wrapSVGFEImageElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEImageElementWrappingImplementation._wrap(raw);
  }

  static SVGFEMergeElement wrapSVGFEMergeElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEMergeElementWrappingImplementation._wrap(raw);
  }

  static SVGFEMergeNodeElement wrapSVGFEMergeNodeElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEMergeNodeElementWrappingImplementation._wrap(raw);
  }

  static SVGFEOffsetElement wrapSVGFEOffsetElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEOffsetElementWrappingImplementation._wrap(raw);
  }

  static SVGFEPointLightElement wrapSVGFEPointLightElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEPointLightElementWrappingImplementation._wrap(raw);
  }

  static SVGFESpecularLightingElement wrapSVGFESpecularLightingElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFESpecularLightingElementWrappingImplementation._wrap(raw);
  }

  static SVGFESpotLightElement wrapSVGFESpotLightElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFESpotLightElementWrappingImplementation._wrap(raw);
  }

  static SVGFETileElement wrapSVGFETileElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFETileElementWrappingImplementation._wrap(raw);
  }

  static SVGFETurbulenceElement wrapSVGFETurbulenceElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFETurbulenceElementWrappingImplementation._wrap(raw);
  }

  static SVGFilterElement wrapSVGFilterElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFilterElementWrappingImplementation._wrap(raw);
  }

  static SVGFilterPrimitiveStandardAttributes wrapSVGFilterPrimitiveStandardAttributes(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGFEBlendElement":
        return new SVGFEBlendElementWrappingImplementation._wrap(raw);
      case "SVGFEColorMatrixElement":
        return new SVGFEColorMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEComponentTransferElement":
        return new SVGFEComponentTransferElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFECompositeElement*/
      case "SVGFEConvolveMatrixElement":
        return new SVGFEConvolveMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEDiffuseLightingElement":
        return new SVGFEDiffuseLightingElementWrappingImplementation._wrap(raw);
      case "SVGFEDisplacementMapElement":
        return new SVGFEDisplacementMapElementWrappingImplementation._wrap(raw);
      case "SVGFEDropShadowElement":
        return new SVGFEDropShadowElementWrappingImplementation._wrap(raw);
      case "SVGFEFloodElement":
        return new SVGFEFloodElementWrappingImplementation._wrap(raw);
      case "SVGFEGaussianBlurElement":
        return new SVGFEGaussianBlurElementWrappingImplementation._wrap(raw);
      case "SVGFEImageElement":
        return new SVGFEImageElementWrappingImplementation._wrap(raw);
      case "SVGFEMergeElement":
        return new SVGFEMergeElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFEMorphologyElement*/
      case "SVGFEOffsetElement":
        return new SVGFEOffsetElementWrappingImplementation._wrap(raw);
      case "SVGFESpecularLightingElement":
        return new SVGFESpecularLightingElementWrappingImplementation._wrap(raw);
      case "SVGFETileElement":
        return new SVGFETileElementWrappingImplementation._wrap(raw);
      case "SVGFETurbulenceElement":
        return new SVGFETurbulenceElementWrappingImplementation._wrap(raw);
      case "SVGFilterPrimitiveStandardAttributes":
        return new SVGFilterPrimitiveStandardAttributesWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGFitToViewBox wrapSVGFitToViewBox(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGFitToViewBox":
        return new SVGFitToViewBoxWrappingImplementation._wrap(raw);
      case "SVGMarkerElement":
        return new SVGMarkerElementWrappingImplementation._wrap(raw);
      case "SVGPatternElement":
        return new SVGPatternElementWrappingImplementation._wrap(raw);
      case "SVGSVGElement":
        return new SVGSVGElementWrappingImplementation._wrap(raw);
      case "SVGSymbolElement":
        return new SVGSymbolElementWrappingImplementation._wrap(raw);
      case "SVGViewElement":
        return new SVGViewElementWrappingImplementation._wrap(raw);
      case "SVGViewSpec":
        return new SVGViewSpecWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGFontElement wrapSVGFontElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFontElementWrappingImplementation._wrap(raw);
  }

  static SVGFontFaceElement wrapSVGFontFaceElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFontFaceElementWrappingImplementation._wrap(raw);
  }

  static SVGFontFaceFormatElement wrapSVGFontFaceFormatElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFontFaceFormatElementWrappingImplementation._wrap(raw);
  }

  static SVGFontFaceNameElement wrapSVGFontFaceNameElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFontFaceNameElementWrappingImplementation._wrap(raw);
  }

  static SVGFontFaceSrcElement wrapSVGFontFaceSrcElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFontFaceSrcElementWrappingImplementation._wrap(raw);
  }

  static SVGFontFaceUriElement wrapSVGFontFaceUriElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFontFaceUriElementWrappingImplementation._wrap(raw);
  }

  static SVGForeignObjectElement wrapSVGForeignObjectElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGForeignObjectElementWrappingImplementation._wrap(raw);
  }

  static SVGGElement wrapSVGGElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGGElementWrappingImplementation._wrap(raw);
  }

  static SVGGlyphElement wrapSVGGlyphElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGGlyphElementWrappingImplementation._wrap(raw);
  }

  static SVGGlyphRefElement wrapSVGGlyphRefElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGGlyphRefElementWrappingImplementation._wrap(raw);
  }

  static SVGGradientElement wrapSVGGradientElement(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGGradientElement":
        return new SVGGradientElementWrappingImplementation._wrap(raw);
      case "SVGLinearGradientElement":
        return new SVGLinearGradientElementWrappingImplementation._wrap(raw);
      case "SVGRadialGradientElement":
        return new SVGRadialGradientElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGHKernElement wrapSVGHKernElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGHKernElementWrappingImplementation._wrap(raw);
  }

  static SVGImageElement wrapSVGImageElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGImageElementWrappingImplementation._wrap(raw);
  }

  static SVGLangSpace wrapSVGLangSpace(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGAElement":
        return new SVGAElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphElement":
        return new SVGAltGlyphElementWrappingImplementation._wrap(raw);
      case "SVGCircleElement":
        return new SVGCircleElementWrappingImplementation._wrap(raw);
      case "SVGClipPathElement":
        return new SVGClipPathElementWrappingImplementation._wrap(raw);
      case "SVGDefsElement":
        return new SVGDefsElementWrappingImplementation._wrap(raw);
      case "SVGDescElement":
        return new SVGDescElementWrappingImplementation._wrap(raw);
      case "SVGEllipseElement":
        return new SVGEllipseElementWrappingImplementation._wrap(raw);
      case "SVGFEImageElement":
        return new SVGFEImageElementWrappingImplementation._wrap(raw);
      case "SVGFilterElement":
        return new SVGFilterElementWrappingImplementation._wrap(raw);
      case "SVGForeignObjectElement":
        return new SVGForeignObjectElementWrappingImplementation._wrap(raw);
      case "SVGGElement":
        return new SVGGElementWrappingImplementation._wrap(raw);
      case "SVGImageElement":
        return new SVGImageElementWrappingImplementation._wrap(raw);
      case "SVGLangSpace":
        return new SVGLangSpaceWrappingImplementation._wrap(raw);
      case "SVGLineElement":
        return new SVGLineElementWrappingImplementation._wrap(raw);
      case "SVGMarkerElement":
        return new SVGMarkerElementWrappingImplementation._wrap(raw);
      case "SVGMaskElement":
        return new SVGMaskElementWrappingImplementation._wrap(raw);
      case "SVGPathElement":
        return new SVGPathElementWrappingImplementation._wrap(raw);
      case "SVGPatternElement":
        return new SVGPatternElementWrappingImplementation._wrap(raw);
      case "SVGPolygonElement":
        return new SVGPolygonElementWrappingImplementation._wrap(raw);
      case "SVGPolylineElement":
        return new SVGPolylineElementWrappingImplementation._wrap(raw);
      case "SVGRectElement":
        return new SVGRectElementWrappingImplementation._wrap(raw);
      case "SVGSVGElement":
        return new SVGSVGElementWrappingImplementation._wrap(raw);
      case "SVGStyleElement":
        return new SVGStyleElementWrappingImplementation._wrap(raw);
      case "SVGSwitchElement":
        return new SVGSwitchElementWrappingImplementation._wrap(raw);
      case "SVGSymbolElement":
        return new SVGSymbolElementWrappingImplementation._wrap(raw);
      case "SVGTRefElement":
        return new SVGTRefElementWrappingImplementation._wrap(raw);
      case "SVGTSpanElement":
        return new SVGTSpanElementWrappingImplementation._wrap(raw);
      case "SVGTextContentElement":
        return new SVGTextContentElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTextPathElement":
        return new SVGTextPathElementWrappingImplementation._wrap(raw);
      case "SVGTextPositioningElement":
        return new SVGTextPositioningElementWrappingImplementation._wrap(raw);
      case "SVGTitleElement":
        return new SVGTitleElementWrappingImplementation._wrap(raw);
      case "SVGUseElement":
        return new SVGUseElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGLength wrapSVGLength(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGLengthWrappingImplementation._wrap(raw);
  }

  static SVGLengthList wrapSVGLengthList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGLengthListWrappingImplementation._wrap(raw);
  }

  static SVGLineElement wrapSVGLineElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGLineElementWrappingImplementation._wrap(raw);
  }

  static SVGLinearGradientElement wrapSVGLinearGradientElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGLinearGradientElementWrappingImplementation._wrap(raw);
  }

  static SVGLocatable wrapSVGLocatable(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGAElement":
        return new SVGAElementWrappingImplementation._wrap(raw);
      case "SVGCircleElement":
        return new SVGCircleElementWrappingImplementation._wrap(raw);
      case "SVGClipPathElement":
        return new SVGClipPathElementWrappingImplementation._wrap(raw);
      case "SVGDefsElement":
        return new SVGDefsElementWrappingImplementation._wrap(raw);
      case "SVGEllipseElement":
        return new SVGEllipseElementWrappingImplementation._wrap(raw);
      case "SVGForeignObjectElement":
        return new SVGForeignObjectElementWrappingImplementation._wrap(raw);
      case "SVGGElement":
        return new SVGGElementWrappingImplementation._wrap(raw);
      case "SVGImageElement":
        return new SVGImageElementWrappingImplementation._wrap(raw);
      case "SVGLineElement":
        return new SVGLineElementWrappingImplementation._wrap(raw);
      case "SVGLocatable":
        return new SVGLocatableWrappingImplementation._wrap(raw);
      case "SVGPathElement":
        return new SVGPathElementWrappingImplementation._wrap(raw);
      case "SVGPolygonElement":
        return new SVGPolygonElementWrappingImplementation._wrap(raw);
      case "SVGPolylineElement":
        return new SVGPolylineElementWrappingImplementation._wrap(raw);
      case "SVGRectElement":
        return new SVGRectElementWrappingImplementation._wrap(raw);
      case "SVGSVGElement":
        return new SVGSVGElementWrappingImplementation._wrap(raw);
      case "SVGSwitchElement":
        return new SVGSwitchElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTransformable":
        return new SVGTransformableWrappingImplementation._wrap(raw);
      case "SVGUseElement":
        return new SVGUseElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGMPathElement wrapSVGMPathElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGMPathElementWrappingImplementation._wrap(raw);
  }

  static SVGMarkerElement wrapSVGMarkerElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGMarkerElementWrappingImplementation._wrap(raw);
  }

  static SVGMaskElement wrapSVGMaskElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGMaskElementWrappingImplementation._wrap(raw);
  }

  static SVGMatrix wrapSVGMatrix(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGMatrixWrappingImplementation._wrap(raw);
  }

  static SVGMetadataElement wrapSVGMetadataElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGMetadataElementWrappingImplementation._wrap(raw);
  }

  static SVGMissingGlyphElement wrapSVGMissingGlyphElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGMissingGlyphElementWrappingImplementation._wrap(raw);
  }

  static SVGNumber wrapSVGNumber(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGNumberWrappingImplementation._wrap(raw);
  }

  static SVGNumberList wrapSVGNumberList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGNumberListWrappingImplementation._wrap(raw);
  }

  static SVGPaint wrapSVGPaint(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPaintWrappingImplementation._wrap(raw);
  }

  static SVGPathElement wrapSVGPathElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathElementWrappingImplementation._wrap(raw);
  }

  static SVGPathSeg wrapSVGPathSeg(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGPathSeg":
        return new SVGPathSegWrappingImplementation._wrap(raw);
      case "SVGPathSegArcAbs":
        return new SVGPathSegArcAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegArcRel":
        return new SVGPathSegArcRelWrappingImplementation._wrap(raw);
      case "SVGPathSegClosePath":
        return new SVGPathSegClosePathWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoCubicAbs":
        return new SVGPathSegCurvetoCubicAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoCubicRel":
        return new SVGPathSegCurvetoCubicRelWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoCubicSmoothAbs":
        return new SVGPathSegCurvetoCubicSmoothAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoCubicSmoothRel":
        return new SVGPathSegCurvetoCubicSmoothRelWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoQuadraticAbs":
        return new SVGPathSegCurvetoQuadraticAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoQuadraticRel":
        return new SVGPathSegCurvetoQuadraticRelWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoQuadraticSmoothAbs":
        return new SVGPathSegCurvetoQuadraticSmoothAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoQuadraticSmoothRel":
        return new SVGPathSegCurvetoQuadraticSmoothRelWrappingImplementation._wrap(raw);
      case "SVGPathSegLinetoAbs":
        return new SVGPathSegLinetoAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegLinetoHorizontalAbs":
        return new SVGPathSegLinetoHorizontalAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegLinetoHorizontalRel":
        return new SVGPathSegLinetoHorizontalRelWrappingImplementation._wrap(raw);
      case "SVGPathSegLinetoRel":
        return new SVGPathSegLinetoRelWrappingImplementation._wrap(raw);
      case "SVGPathSegLinetoVerticalAbs":
        return new SVGPathSegLinetoVerticalAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegLinetoVerticalRel":
        return new SVGPathSegLinetoVerticalRelWrappingImplementation._wrap(raw);
      case "SVGPathSegMovetoAbs":
        return new SVGPathSegMovetoAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegMovetoRel":
        return new SVGPathSegMovetoRelWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGPathSegArcAbs wrapSVGPathSegArcAbs(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegArcAbsWrappingImplementation._wrap(raw);
  }

  static SVGPathSegArcRel wrapSVGPathSegArcRel(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegArcRelWrappingImplementation._wrap(raw);
  }

  static SVGPathSegClosePath wrapSVGPathSegClosePath(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegClosePathWrappingImplementation._wrap(raw);
  }

  static SVGPathSegCurvetoCubicAbs wrapSVGPathSegCurvetoCubicAbs(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegCurvetoCubicAbsWrappingImplementation._wrap(raw);
  }

  static SVGPathSegCurvetoCubicRel wrapSVGPathSegCurvetoCubicRel(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegCurvetoCubicRelWrappingImplementation._wrap(raw);
  }

  static SVGPathSegCurvetoCubicSmoothAbs wrapSVGPathSegCurvetoCubicSmoothAbs(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegCurvetoCubicSmoothAbsWrappingImplementation._wrap(raw);
  }

  static SVGPathSegCurvetoCubicSmoothRel wrapSVGPathSegCurvetoCubicSmoothRel(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegCurvetoCubicSmoothRelWrappingImplementation._wrap(raw);
  }

  static SVGPathSegCurvetoQuadraticAbs wrapSVGPathSegCurvetoQuadraticAbs(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegCurvetoQuadraticAbsWrappingImplementation._wrap(raw);
  }

  static SVGPathSegCurvetoQuadraticRel wrapSVGPathSegCurvetoQuadraticRel(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegCurvetoQuadraticRelWrappingImplementation._wrap(raw);
  }

  static SVGPathSegCurvetoQuadraticSmoothAbs wrapSVGPathSegCurvetoQuadraticSmoothAbs(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegCurvetoQuadraticSmoothAbsWrappingImplementation._wrap(raw);
  }

  static SVGPathSegCurvetoQuadraticSmoothRel wrapSVGPathSegCurvetoQuadraticSmoothRel(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegCurvetoQuadraticSmoothRelWrappingImplementation._wrap(raw);
  }

  static SVGPathSegLinetoAbs wrapSVGPathSegLinetoAbs(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegLinetoAbsWrappingImplementation._wrap(raw);
  }

  static SVGPathSegLinetoHorizontalAbs wrapSVGPathSegLinetoHorizontalAbs(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegLinetoHorizontalAbsWrappingImplementation._wrap(raw);
  }

  static SVGPathSegLinetoHorizontalRel wrapSVGPathSegLinetoHorizontalRel(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegLinetoHorizontalRelWrappingImplementation._wrap(raw);
  }

  static SVGPathSegLinetoRel wrapSVGPathSegLinetoRel(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegLinetoRelWrappingImplementation._wrap(raw);
  }

  static SVGPathSegLinetoVerticalAbs wrapSVGPathSegLinetoVerticalAbs(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegLinetoVerticalAbsWrappingImplementation._wrap(raw);
  }

  static SVGPathSegLinetoVerticalRel wrapSVGPathSegLinetoVerticalRel(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegLinetoVerticalRelWrappingImplementation._wrap(raw);
  }

  static SVGPathSegList wrapSVGPathSegList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegListWrappingImplementation._wrap(raw);
  }

  static SVGPathSegMovetoAbs wrapSVGPathSegMovetoAbs(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegMovetoAbsWrappingImplementation._wrap(raw);
  }

  static SVGPathSegMovetoRel wrapSVGPathSegMovetoRel(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegMovetoRelWrappingImplementation._wrap(raw);
  }

  static SVGPatternElement wrapSVGPatternElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPatternElementWrappingImplementation._wrap(raw);
  }

  static SVGPoint wrapSVGPoint(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPointWrappingImplementation._wrap(raw);
  }

  static SVGPointList wrapSVGPointList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPointListWrappingImplementation._wrap(raw);
  }

  static SVGPolygonElement wrapSVGPolygonElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPolygonElementWrappingImplementation._wrap(raw);
  }

  static SVGPolylineElement wrapSVGPolylineElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPolylineElementWrappingImplementation._wrap(raw);
  }

  static SVGPreserveAspectRatio wrapSVGPreserveAspectRatio(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPreserveAspectRatioWrappingImplementation._wrap(raw);
  }

  static SVGRadialGradientElement wrapSVGRadialGradientElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGRadialGradientElementWrappingImplementation._wrap(raw);
  }

  static SVGRect wrapSVGRect(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGRectWrappingImplementation._wrap(raw);
  }

  static SVGRectElement wrapSVGRectElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGRectElementWrappingImplementation._wrap(raw);
  }

  static SVGRenderingIntent wrapSVGRenderingIntent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGRenderingIntentWrappingImplementation._wrap(raw);
  }

  static SVGSVGElement wrapSVGSVGElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGSVGElementWrappingImplementation._wrap(raw);
  }

  static SVGScriptElement wrapSVGScriptElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGScriptElementWrappingImplementation._wrap(raw);
  }

  static SVGSetElement wrapSVGSetElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGSetElementWrappingImplementation._wrap(raw);
  }

  static SVGStopElement wrapSVGStopElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGStopElementWrappingImplementation._wrap(raw);
  }

  static SVGStringList wrapSVGStringList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGStringListWrappingImplementation._wrap(raw);
  }

  static SVGStylable wrapSVGStylable(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGAElement":
        return new SVGAElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphElement":
        return new SVGAltGlyphElementWrappingImplementation._wrap(raw);
      case "SVGCircleElement":
        return new SVGCircleElementWrappingImplementation._wrap(raw);
      case "SVGClipPathElement":
        return new SVGClipPathElementWrappingImplementation._wrap(raw);
      case "SVGDefsElement":
        return new SVGDefsElementWrappingImplementation._wrap(raw);
      case "SVGDescElement":
        return new SVGDescElementWrappingImplementation._wrap(raw);
      case "SVGEllipseElement":
        return new SVGEllipseElementWrappingImplementation._wrap(raw);
      case "SVGFEBlendElement":
        return new SVGFEBlendElementWrappingImplementation._wrap(raw);
      case "SVGFEColorMatrixElement":
        return new SVGFEColorMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEComponentTransferElement":
        return new SVGFEComponentTransferElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFECompositeElement*/
      case "SVGFEConvolveMatrixElement":
        return new SVGFEConvolveMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEDiffuseLightingElement":
        return new SVGFEDiffuseLightingElementWrappingImplementation._wrap(raw);
      case "SVGFEDisplacementMapElement":
        return new SVGFEDisplacementMapElementWrappingImplementation._wrap(raw);
      case "SVGFEDropShadowElement":
        return new SVGFEDropShadowElementWrappingImplementation._wrap(raw);
      case "SVGFEFloodElement":
        return new SVGFEFloodElementWrappingImplementation._wrap(raw);
      case "SVGFEGaussianBlurElement":
        return new SVGFEGaussianBlurElementWrappingImplementation._wrap(raw);
      case "SVGFEImageElement":
        return new SVGFEImageElementWrappingImplementation._wrap(raw);
      case "SVGFEMergeElement":
        return new SVGFEMergeElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFEMorphologyElement*/
      case "SVGFEOffsetElement":
        return new SVGFEOffsetElementWrappingImplementation._wrap(raw);
      case "SVGFESpecularLightingElement":
        return new SVGFESpecularLightingElementWrappingImplementation._wrap(raw);
      case "SVGFETileElement":
        return new SVGFETileElementWrappingImplementation._wrap(raw);
      case "SVGFETurbulenceElement":
        return new SVGFETurbulenceElementWrappingImplementation._wrap(raw);
      case "SVGFilterElement":
        return new SVGFilterElementWrappingImplementation._wrap(raw);
      case "SVGFilterPrimitiveStandardAttributes":
        return new SVGFilterPrimitiveStandardAttributesWrappingImplementation._wrap(raw);
      case "SVGForeignObjectElement":
        return new SVGForeignObjectElementWrappingImplementation._wrap(raw);
      case "SVGGElement":
        return new SVGGElementWrappingImplementation._wrap(raw);
      case "SVGGlyphRefElement":
        return new SVGGlyphRefElementWrappingImplementation._wrap(raw);
      case "SVGGradientElement":
        return new SVGGradientElementWrappingImplementation._wrap(raw);
      case "SVGImageElement":
        return new SVGImageElementWrappingImplementation._wrap(raw);
      case "SVGLineElement":
        return new SVGLineElementWrappingImplementation._wrap(raw);
      case "SVGLinearGradientElement":
        return new SVGLinearGradientElementWrappingImplementation._wrap(raw);
      case "SVGMarkerElement":
        return new SVGMarkerElementWrappingImplementation._wrap(raw);
      case "SVGMaskElement":
        return new SVGMaskElementWrappingImplementation._wrap(raw);
      case "SVGPathElement":
        return new SVGPathElementWrappingImplementation._wrap(raw);
      case "SVGPatternElement":
        return new SVGPatternElementWrappingImplementation._wrap(raw);
      case "SVGPolygonElement":
        return new SVGPolygonElementWrappingImplementation._wrap(raw);
      case "SVGPolylineElement":
        return new SVGPolylineElementWrappingImplementation._wrap(raw);
      case "SVGRadialGradientElement":
        return new SVGRadialGradientElementWrappingImplementation._wrap(raw);
      case "SVGRectElement":
        return new SVGRectElementWrappingImplementation._wrap(raw);
      case "SVGSVGElement":
        return new SVGSVGElementWrappingImplementation._wrap(raw);
      case "SVGStopElement":
        return new SVGStopElementWrappingImplementation._wrap(raw);
      case "SVGStylable":
        return new SVGStylableWrappingImplementation._wrap(raw);
      case "SVGSwitchElement":
        return new SVGSwitchElementWrappingImplementation._wrap(raw);
      case "SVGSymbolElement":
        return new SVGSymbolElementWrappingImplementation._wrap(raw);
      case "SVGTRefElement":
        return new SVGTRefElementWrappingImplementation._wrap(raw);
      case "SVGTSpanElement":
        return new SVGTSpanElementWrappingImplementation._wrap(raw);
      case "SVGTextContentElement":
        return new SVGTextContentElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTextPathElement":
        return new SVGTextPathElementWrappingImplementation._wrap(raw);
      case "SVGTextPositioningElement":
        return new SVGTextPositioningElementWrappingImplementation._wrap(raw);
      case "SVGTitleElement":
        return new SVGTitleElementWrappingImplementation._wrap(raw);
      case "SVGUseElement":
        return new SVGUseElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGStyleElement wrapSVGStyleElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGStyleElementWrappingImplementation._wrap(raw);
  }

  static SVGSwitchElement wrapSVGSwitchElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGSwitchElementWrappingImplementation._wrap(raw);
  }

  static SVGSymbolElement wrapSVGSymbolElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGSymbolElementWrappingImplementation._wrap(raw);
  }

  static SVGTRefElement wrapSVGTRefElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGTRefElementWrappingImplementation._wrap(raw);
  }

  static SVGTSpanElement wrapSVGTSpanElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGTSpanElementWrappingImplementation._wrap(raw);
  }

  static SVGTests wrapSVGTests(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGAElement":
        return new SVGAElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphElement":
        return new SVGAltGlyphElementWrappingImplementation._wrap(raw);
      case "SVGAnimateColorElement":
        return new SVGAnimateColorElementWrappingImplementation._wrap(raw);
      case "SVGAnimateElement":
        return new SVGAnimateElementWrappingImplementation._wrap(raw);
      case "SVGAnimateMotionElement":
        return new SVGAnimateMotionElementWrappingImplementation._wrap(raw);
      case "SVGAnimateTransformElement":
        return new SVGAnimateTransformElementWrappingImplementation._wrap(raw);
      case "SVGAnimationElement":
        return new SVGAnimationElementWrappingImplementation._wrap(raw);
      case "SVGCircleElement":
        return new SVGCircleElementWrappingImplementation._wrap(raw);
      case "SVGClipPathElement":
        return new SVGClipPathElementWrappingImplementation._wrap(raw);
      case "SVGCursorElement":
        return new SVGCursorElementWrappingImplementation._wrap(raw);
      case "SVGDefsElement":
        return new SVGDefsElementWrappingImplementation._wrap(raw);
      case "SVGEllipseElement":
        return new SVGEllipseElementWrappingImplementation._wrap(raw);
      case "SVGForeignObjectElement":
        return new SVGForeignObjectElementWrappingImplementation._wrap(raw);
      case "SVGGElement":
        return new SVGGElementWrappingImplementation._wrap(raw);
      case "SVGImageElement":
        return new SVGImageElementWrappingImplementation._wrap(raw);
      case "SVGLineElement":
        return new SVGLineElementWrappingImplementation._wrap(raw);
      case "SVGMaskElement":
        return new SVGMaskElementWrappingImplementation._wrap(raw);
      case "SVGPathElement":
        return new SVGPathElementWrappingImplementation._wrap(raw);
      case "SVGPatternElement":
        return new SVGPatternElementWrappingImplementation._wrap(raw);
      case "SVGPolygonElement":
        return new SVGPolygonElementWrappingImplementation._wrap(raw);
      case "SVGPolylineElement":
        return new SVGPolylineElementWrappingImplementation._wrap(raw);
      case "SVGRectElement":
        return new SVGRectElementWrappingImplementation._wrap(raw);
      case "SVGSVGElement":
        return new SVGSVGElementWrappingImplementation._wrap(raw);
      case "SVGSetElement":
        return new SVGSetElementWrappingImplementation._wrap(raw);
      case "SVGSwitchElement":
        return new SVGSwitchElementWrappingImplementation._wrap(raw);
      case "SVGTRefElement":
        return new SVGTRefElementWrappingImplementation._wrap(raw);
      case "SVGTSpanElement":
        return new SVGTSpanElementWrappingImplementation._wrap(raw);
      case "SVGTests":
        return new SVGTestsWrappingImplementation._wrap(raw);
      case "SVGTextContentElement":
        return new SVGTextContentElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTextPathElement":
        return new SVGTextPathElementWrappingImplementation._wrap(raw);
      case "SVGTextPositioningElement":
        return new SVGTextPositioningElementWrappingImplementation._wrap(raw);
      case "SVGUseElement":
        return new SVGUseElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGTextContentElement wrapSVGTextContentElement(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGAltGlyphElement":
        return new SVGAltGlyphElementWrappingImplementation._wrap(raw);
      case "SVGTRefElement":
        return new SVGTRefElementWrappingImplementation._wrap(raw);
      case "SVGTSpanElement":
        return new SVGTSpanElementWrappingImplementation._wrap(raw);
      case "SVGTextContentElement":
        return new SVGTextContentElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTextPathElement":
        return new SVGTextPathElementWrappingImplementation._wrap(raw);
      case "SVGTextPositioningElement":
        return new SVGTextPositioningElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGTextElement wrapSVGTextElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGTextElementWrappingImplementation._wrap(raw);
  }

  static SVGTextPathElement wrapSVGTextPathElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGTextPathElementWrappingImplementation._wrap(raw);
  }

  static SVGTextPositioningElement wrapSVGTextPositioningElement(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGAltGlyphElement":
        return new SVGAltGlyphElementWrappingImplementation._wrap(raw);
      case "SVGTRefElement":
        return new SVGTRefElementWrappingImplementation._wrap(raw);
      case "SVGTSpanElement":
        return new SVGTSpanElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTextPositioningElement":
        return new SVGTextPositioningElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGTitleElement wrapSVGTitleElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGTitleElementWrappingImplementation._wrap(raw);
  }

  static SVGTransform wrapSVGTransform(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGTransformWrappingImplementation._wrap(raw);
  }

  static SVGTransformList wrapSVGTransformList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGTransformListWrappingImplementation._wrap(raw);
  }

  static SVGTransformable wrapSVGTransformable(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGAElement":
        return new SVGAElementWrappingImplementation._wrap(raw);
      case "SVGCircleElement":
        return new SVGCircleElementWrappingImplementation._wrap(raw);
      case "SVGClipPathElement":
        return new SVGClipPathElementWrappingImplementation._wrap(raw);
      case "SVGDefsElement":
        return new SVGDefsElementWrappingImplementation._wrap(raw);
      case "SVGEllipseElement":
        return new SVGEllipseElementWrappingImplementation._wrap(raw);
      case "SVGForeignObjectElement":
        return new SVGForeignObjectElementWrappingImplementation._wrap(raw);
      case "SVGGElement":
        return new SVGGElementWrappingImplementation._wrap(raw);
      case "SVGImageElement":
        return new SVGImageElementWrappingImplementation._wrap(raw);
      case "SVGLineElement":
        return new SVGLineElementWrappingImplementation._wrap(raw);
      case "SVGPathElement":
        return new SVGPathElementWrappingImplementation._wrap(raw);
      case "SVGPolygonElement":
        return new SVGPolygonElementWrappingImplementation._wrap(raw);
      case "SVGPolylineElement":
        return new SVGPolylineElementWrappingImplementation._wrap(raw);
      case "SVGRectElement":
        return new SVGRectElementWrappingImplementation._wrap(raw);
      case "SVGSwitchElement":
        return new SVGSwitchElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTransformable":
        return new SVGTransformableWrappingImplementation._wrap(raw);
      case "SVGUseElement":
        return new SVGUseElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGURIReference wrapSVGURIReference(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGAElement":
        return new SVGAElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphElement":
        return new SVGAltGlyphElementWrappingImplementation._wrap(raw);
      case "SVGCursorElement":
        return new SVGCursorElementWrappingImplementation._wrap(raw);
      case "SVGFEImageElement":
        return new SVGFEImageElementWrappingImplementation._wrap(raw);
      case "SVGFilterElement":
        return new SVGFilterElementWrappingImplementation._wrap(raw);
      case "SVGGlyphRefElement":
        return new SVGGlyphRefElementWrappingImplementation._wrap(raw);
      case "SVGGradientElement":
        return new SVGGradientElementWrappingImplementation._wrap(raw);
      case "SVGImageElement":
        return new SVGImageElementWrappingImplementation._wrap(raw);
      case "SVGLinearGradientElement":
        return new SVGLinearGradientElementWrappingImplementation._wrap(raw);
      case "SVGMPathElement":
        return new SVGMPathElementWrappingImplementation._wrap(raw);
      case "SVGPatternElement":
        return new SVGPatternElementWrappingImplementation._wrap(raw);
      case "SVGRadialGradientElement":
        return new SVGRadialGradientElementWrappingImplementation._wrap(raw);
      case "SVGScriptElement":
        return new SVGScriptElementWrappingImplementation._wrap(raw);
      case "SVGTRefElement":
        return new SVGTRefElementWrappingImplementation._wrap(raw);
      case "SVGTextPathElement":
        return new SVGTextPathElementWrappingImplementation._wrap(raw);
      case "SVGURIReference":
        return new SVGURIReferenceWrappingImplementation._wrap(raw);
      case "SVGUseElement":
        return new SVGUseElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGUnitTypes wrapSVGUnitTypes(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGUnitTypesWrappingImplementation._wrap(raw);
  }

  static SVGUseElement wrapSVGUseElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGUseElementWrappingImplementation._wrap(raw);
  }

  static SVGVKernElement wrapSVGVKernElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGVKernElementWrappingImplementation._wrap(raw);
  }

  static SVGViewElement wrapSVGViewElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGViewElementWrappingImplementation._wrap(raw);
  }

  static SVGViewSpec wrapSVGViewSpec(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGViewSpecWrappingImplementation._wrap(raw);
  }

  static SVGZoomAndPan wrapSVGZoomAndPan(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGSVGElement":
        return new SVGSVGElementWrappingImplementation._wrap(raw);
      case "SVGViewElement":
        return new SVGViewElementWrappingImplementation._wrap(raw);
      case "SVGViewSpec":
        return new SVGViewSpecWrappingImplementation._wrap(raw);
      case "SVGZoomAndPan":
        return new SVGZoomAndPanWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGZoomEvent wrapSVGZoomEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGZoomEventWrappingImplementation._wrap(raw);
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

  // Skipped StorageInfoErrorCallback
  // Skipped StorageInfoQuotaCallback
  // Skipped StorageInfoUsageCallback
  // Skipped StringCallback
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

  static TextTrack wrapTextTrack(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TextTrackWrappingImplementation._wrap(raw);
  }

  static TextTrackCue wrapTextTrackCue(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TextTrackCueWrappingImplementation._wrap(raw);
  }

  static TextTrackCueList wrapTextTrackCueList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TextTrackCueListWrappingImplementation._wrap(raw);
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
      case "SVGZoomEvent":
        return new SVGZoomEventWrappingImplementation._wrap(raw);
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

  static WaveShaperNode wrapWaveShaperNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WaveShaperNodeWrappingImplementation._wrap(raw);
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

  static WebGLDebugRendererInfo wrapWebGLDebugRendererInfo(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLDebugRendererInfoWrappingImplementation._wrap(raw);
  }

  static WebGLDebugShaders wrapWebGLDebugShaders(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLDebugShadersWrappingImplementation._wrap(raw);
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

  static WebKitCSSFilterValue wrapWebKitCSSFilterValue(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebKitCSSFilterValueWrappingImplementation._wrap(raw);
  }

  static WebKitMutationObserver wrapWebKitMutationObserver(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebKitMutationObserverWrappingImplementation._wrap(raw);
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

  static Object wrapObject(raw) {
    if (raw === null || raw is String || raw is num || raw is Date) { return raw; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      /* Skipping AbstractWorker*/
      case "HTMLAnchorElement":
        return new AnchorElementWrappingImplementation._wrap(raw);
      case "WebKitAnimation":
        return new AnimationWrappingImplementation._wrap(raw);
      case "WebKitAnimationEvent":
        return new AnimationEventWrappingImplementation._wrap(raw);
      case "WebKitAnimationList":
        return new AnimationListWrappingImplementation._wrap(raw);
      /* Skipping HTMLAppletElement*/
      case "HTMLAreaElement":
        return new AreaElementWrappingImplementation._wrap(raw);
      case "ArrayBuffer":
        return new ArrayBufferWrappingImplementation._wrap(raw);
      case "ArrayBufferView":
        return new ArrayBufferViewWrappingImplementation._wrap(raw);
      /* Skipping Attr*/
      case "AudioBuffer":
        return new AudioBufferWrappingImplementation._wrap(raw);
      /* Skipping AudioBufferCallback*/
      case "AudioBufferSourceNode":
        return new AudioBufferSourceNodeWrappingImplementation._wrap(raw);
      case "AudioChannelMerger":
        return new AudioChannelMergerWrappingImplementation._wrap(raw);
      case "AudioChannelSplitter":
        return new AudioChannelSplitterWrappingImplementation._wrap(raw);
      case "AudioContext":
        return new AudioContextWrappingImplementation._wrap(raw);
      case "AudioDestinationNode":
        return new AudioDestinationNodeWrappingImplementation._wrap(raw);
      case "HTMLAudioElement":
        return new AudioElementWrappingImplementation._wrap(raw);
      case "AudioGain":
        return new AudioGainWrappingImplementation._wrap(raw);
      case "AudioGainNode":
        return new AudioGainNodeWrappingImplementation._wrap(raw);
      case "AudioListener":
        return new AudioListenerWrappingImplementation._wrap(raw);
      case "AudioNode":
        return new AudioNodeWrappingImplementation._wrap(raw);
      case "AudioPannerNode":
        return new AudioPannerNodeWrappingImplementation._wrap(raw);
      case "AudioParam":
        return new AudioParamWrappingImplementation._wrap(raw);
      case "AudioProcessingEvent":
        return new AudioProcessingEventWrappingImplementation._wrap(raw);
      case "AudioSourceNode":
        return new AudioSourceNodeWrappingImplementation._wrap(raw);
      case "HTMLBRElement":
        return new BRElementWrappingImplementation._wrap(raw);
      case "BarInfo":
        return new BarInfoWrappingImplementation._wrap(raw);
      case "HTMLBaseElement":
        return new BaseElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLBaseFontElement*/
      case "BeforeLoadEvent":
        return new BeforeLoadEventWrappingImplementation._wrap(raw);
      case "BiquadFilterNode":
        return new BiquadFilterNodeWrappingImplementation._wrap(raw);
      case "Blob":
        return new BlobWrappingImplementation._wrap(raw);
      case "WebKitBlobBuilder":
        return new BlobBuilderWrappingImplementation._wrap(raw);
      case "HTMLBodyElement":
        return new BodyElementWrappingImplementation._wrap(raw);
      case "HTMLButtonElement":
        return new ButtonElementWrappingImplementation._wrap(raw);
      case "CDATASection":
        return new CDATASectionWrappingImplementation._wrap(raw);
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
      case "WebKitCSSMatrix":
        return new CSSMatrixWrappingImplementation._wrap(raw);
      case "CSSMediaRule":
        return new CSSMediaRuleWrappingImplementation._wrap(raw);
      case "CSSPageRule":
        return new CSSPageRuleWrappingImplementation._wrap(raw);
      case "CSSPrimitiveValue":
        return new CSSPrimitiveValueWrappingImplementation._wrap(raw);
      case "CSSRule":
        return new CSSRuleWrappingImplementation._wrap(raw);
      case "CSSRuleList":
        return new CSSRuleListWrappingImplementation._wrap(raw);
      case "CSSStyleDeclaration":
        return new CSSStyleDeclarationWrappingImplementation._wrap(raw);
      case "CSSStyleRule":
        return new CSSStyleRuleWrappingImplementation._wrap(raw);
      case "CSSStyleSheet":
        return new CSSStyleSheetWrappingImplementation._wrap(raw);
      case "WebKitCSSTransformValue":
        return new CSSTransformValueWrappingImplementation._wrap(raw);
      case "CSSUnknownRule":
        return new CSSUnknownRuleWrappingImplementation._wrap(raw);
      case "CSSValue":
        return new CSSValueWrappingImplementation._wrap(raw);
      case "CSSValueList":
        return new CSSValueListWrappingImplementation._wrap(raw);
      case "HTMLCanvasElement":
        return new CanvasElementWrappingImplementation._wrap(raw);
      case "CanvasGradient":
        return new CanvasGradientWrappingImplementation._wrap(raw);
      case "CanvasPattern":
        return new CanvasPatternWrappingImplementation._wrap(raw);
      case "CanvasPixelArray":
        return new CanvasPixelArrayWrappingImplementation._wrap(raw);
      case "CanvasRenderingContext":
        return new CanvasRenderingContextWrappingImplementation._wrap(raw);
      case "CanvasRenderingContext2D":
        return new CanvasRenderingContext2DWrappingImplementation._wrap(raw);
      case "CharacterData":
        return new CharacterDataWrappingImplementation._wrap(raw);
      case "ClientRect":
        return new ClientRectWrappingImplementation._wrap(raw);
      case "ClientRectList":
        return new ClientRectListWrappingImplementation._wrap(raw);
      case "Clipboard":
        return new ClipboardWrappingImplementation._wrap(raw);
      case "CloseEvent":
        return new CloseEventWrappingImplementation._wrap(raw);
      case "Comment":
        return new CommentWrappingImplementation._wrap(raw);
      case "CompositionEvent":
        return new CompositionEventWrappingImplementation._wrap(raw);
      case "Console":
        return new ConsoleWrappingImplementation._wrap(raw);
      case "ConvolverNode":
        return new ConvolverNodeWrappingImplementation._wrap(raw);
      case "Coordinates":
        return new CoordinatesWrappingImplementation._wrap(raw);
      case "Counter":
        return new CounterWrappingImplementation._wrap(raw);
      case "Crypto":
        return new CryptoWrappingImplementation._wrap(raw);
      case "CustomEvent":
        return new CustomEventWrappingImplementation._wrap(raw);
      case "HTMLDListElement":
        return new DListElementWrappingImplementation._wrap(raw);
      case "DOMApplicationCache":
        return new DOMApplicationCacheWrappingImplementation._wrap(raw);
      case "DOMException":
        return new DOMExceptionWrappingImplementation._wrap(raw);
      case "DOMFileSystem":
        return new DOMFileSystemWrappingImplementation._wrap(raw);
      case "DOMFileSystemSync":
        return new DOMFileSystemSyncWrappingImplementation._wrap(raw);
      case "DOMFormData":
        return new DOMFormDataWrappingImplementation._wrap(raw);
      /* Skipping DOMImplementation*/
      case "DOMMimeType":
        return new DOMMimeTypeWrappingImplementation._wrap(raw);
      case "DOMMimeTypeArray":
        return new DOMMimeTypeArrayWrappingImplementation._wrap(raw);
      case "DOMParser":
        return new DOMParserWrappingImplementation._wrap(raw);
      case "DOMPlugin":
        return new DOMPluginWrappingImplementation._wrap(raw);
      case "DOMPluginArray":
        return new DOMPluginArrayWrappingImplementation._wrap(raw);
      case "DOMSelection":
        return new DOMSelectionWrappingImplementation._wrap(raw);
      case "DOMSettableTokenList":
        return new DOMSettableTokenListWrappingImplementation._wrap(raw);
      case "DOMTokenList":
        return new DOMTokenListWrappingImplementation._wrap(raw);
      case "DOMURL":
        return new DOMURLWrappingImplementation._wrap(raw);
      case "HTMLDataListElement":
        return new DataListElementWrappingImplementation._wrap(raw);
      case "DataTransferItem":
        return new DataTransferItemWrappingImplementation._wrap(raw);
      case "DataTransferItemList":
        return new DataTransferItemListWrappingImplementation._wrap(raw);
      case "DataView":
        return new DataViewWrappingImplementation._wrap(raw);
      /* Skipping Database*/
      /* Skipping DatabaseCallback*/
      /* Skipping DatabaseSync*/
      /* Skipping DedicatedWorkerContext*/
      case "DelayNode":
        return new DelayNodeWrappingImplementation._wrap(raw);
      case "HTMLDetailsElement":
        return new DetailsElementWrappingImplementation._wrap(raw);
      case "DeviceMotionEvent":
        return new DeviceMotionEventWrappingImplementation._wrap(raw);
      case "DeviceOrientationEvent":
        return new DeviceOrientationEventWrappingImplementation._wrap(raw);
      /* Skipping HTMLDirectoryElement*/
      case "DirectoryEntry":
        return new DirectoryEntryWrappingImplementation._wrap(raw);
      case "DirectoryEntrySync":
        return new DirectoryEntrySyncWrappingImplementation._wrap(raw);
      case "DirectoryReader":
        return new DirectoryReaderWrappingImplementation._wrap(raw);
      case "DirectoryReaderSync":
        return new DirectoryReaderSyncWrappingImplementation._wrap(raw);
      case "HTMLDivElement":
        return new DivElementWrappingImplementation._wrap(raw);
      case "HTMLDocument":
        return new DocumentWrappingImplementation._wrap(raw, raw.documentElement);
      case "DocumentFragment":
        return new DocumentFragmentWrappingImplementation._wrap(raw);
      /* Skipping DocumentType*/
      case "DynamicsCompressorNode":
        return new DynamicsCompressorNodeWrappingImplementation._wrap(raw);
      case "HTMLElement":
        return new ElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLOptionsCollection*/
      case "ElementTimeControl":
        return new ElementTimeControlWrappingImplementation._wrap(raw);
      /* Skipping ElementTraversal*/
      case "HTMLEmbedElement":
        return new EmbedElementWrappingImplementation._wrap(raw);
      case "Entity":
        return new EntityWrappingImplementation._wrap(raw);
      case "EntityReference":
        return new EntityReferenceWrappingImplementation._wrap(raw);
      /* Skipping EntriesCallback*/
      case "Entry":
        return new EntryWrappingImplementation._wrap(raw);
      case "EntryArray":
        return new EntryArrayWrappingImplementation._wrap(raw);
      case "EntryArraySync":
        return new EntryArraySyncWrappingImplementation._wrap(raw);
      /* Skipping EntryCallback*/
      case "EntrySync":
        return new EntrySyncWrappingImplementation._wrap(raw);
      /* Skipping ErrorCallback*/
      case "ErrorEvent":
        return new ErrorEventWrappingImplementation._wrap(raw);
      case "Event":
        return new EventWrappingImplementation._wrap(raw);
      case "EventException":
        return new EventExceptionWrappingImplementation._wrap(raw);
      /* Skipping EventListener*/
      case "EventSource":
        return new EventSourceWrappingImplementation._wrap(raw);
      case "EventTarget":
        return new EventTargetWrappingImplementation._wrap(raw);
      case "HTMLFieldSetElement":
        return new FieldSetElementWrappingImplementation._wrap(raw);
      case "File":
        return new FileWrappingImplementation._wrap(raw);
      /* Skipping FileCallback*/
      case "FileEntry":
        return new FileEntryWrappingImplementation._wrap(raw);
      case "FileEntrySync":
        return new FileEntrySyncWrappingImplementation._wrap(raw);
      case "FileError":
        return new FileErrorWrappingImplementation._wrap(raw);
      case "FileException":
        return new FileExceptionWrappingImplementation._wrap(raw);
      case "FileList":
        return new FileListWrappingImplementation._wrap(raw);
      case "FileReader":
        return new FileReaderWrappingImplementation._wrap(raw);
      case "FileReaderSync":
        return new FileReaderSyncWrappingImplementation._wrap(raw);
      /* Skipping FileSystemCallback*/
      case "FileWriter":
        return new FileWriterWrappingImplementation._wrap(raw);
      /* Skipping FileWriterCallback*/
      case "FileWriterSync":
        return new FileWriterSyncWrappingImplementation._wrap(raw);
      case "WebKitFlags":
        return new FlagsWrappingImplementation._wrap(raw);
      case "Float32Array":
        return new Float32ArrayWrappingImplementation._wrap(raw);
      case "Float64Array":
        return new Float64ArrayWrappingImplementation._wrap(raw);
      case "HTMLFontElement":
        return new FontElementWrappingImplementation._wrap(raw);
      case "HTMLFormElement":
        return new FormElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLFrameElement*/
      /* Skipping HTMLFrameSetElement*/
      case "Geolocation":
        return new GeolocationWrappingImplementation._wrap(raw);
      case "Geoposition":
        return new GeopositionWrappingImplementation._wrap(raw);
      case "HTMLHRElement":
        return new HRElementWrappingImplementation._wrap(raw);
      case "HTMLAllCollection":
        return new HTMLAllCollectionWrappingImplementation._wrap(raw);
      case "HashChangeEvent":
        return new HashChangeEventWrappingImplementation._wrap(raw);
      case "HTMLHeadElement":
        return new HeadElementWrappingImplementation._wrap(raw);
      case "HTMLHeadingElement":
        return new HeadingElementWrappingImplementation._wrap(raw);
      case "HighPass2FilterNode":
        return new HighPass2FilterNodeWrappingImplementation._wrap(raw);
      case "History":
        return new HistoryWrappingImplementation._wrap(raw);
      case "HTMLHtmlElement":
        return new DocumentWrappingImplementation._wrap(raw.parentNode, raw);
      case "IDBAny":
        return new IDBAnyWrappingImplementation._wrap(raw);
      case "IDBCursor":
        return new IDBCursorWrappingImplementation._wrap(raw);
      case "IDBCursorWithValue":
        return new IDBCursorWithValueWrappingImplementation._wrap(raw);
      case "IDBDatabase":
        return new IDBDatabaseWrappingImplementation._wrap(raw);
      case "IDBDatabaseError":
        return new IDBDatabaseErrorWrappingImplementation._wrap(raw);
      case "IDBDatabaseException":
        return new IDBDatabaseExceptionWrappingImplementation._wrap(raw);
      case "IDBFactory":
        return new IDBFactoryWrappingImplementation._wrap(raw);
      case "IDBIndex":
        return new IDBIndexWrappingImplementation._wrap(raw);
      case "IDBKey":
        return new IDBKeyWrappingImplementation._wrap(raw);
      case "IDBKeyRange":
        return new IDBKeyRangeWrappingImplementation._wrap(raw);
      case "IDBObjectStore":
        return new IDBObjectStoreWrappingImplementation._wrap(raw);
      case "IDBRequest":
        return new IDBRequestWrappingImplementation._wrap(raw);
      case "IDBTransaction":
        return new IDBTransactionWrappingImplementation._wrap(raw);
      case "IDBVersionChangeEvent":
        return new IDBVersionChangeEventWrappingImplementation._wrap(raw);
      case "IDBVersionChangeRequest":
        return new IDBVersionChangeRequestWrappingImplementation._wrap(raw);
      case "HTMLIFrameElement":
        return new IFrameElementWrappingImplementation._wrap(raw);
      case "ImageData":
        return new ImageDataWrappingImplementation._wrap(raw);
      case "HTMLImageElement":
        return new ImageElementWrappingImplementation._wrap(raw);
      /* Skipping InjectedScriptHost*/
      case "HTMLInputElement":
        return new InputElementWrappingImplementation._wrap(raw);
      /* Skipping InspectorFrontendHost*/
      case "Int16Array":
        return new Int16ArrayWrappingImplementation._wrap(raw);
      case "Int32Array":
        return new Int32ArrayWrappingImplementation._wrap(raw);
      case "Int8Array":
        return new Int8ArrayWrappingImplementation._wrap(raw);
      /* Skipping HTMLIsIndexElement*/
      case "JavaScriptAudioNode":
        return new JavaScriptAudioNodeWrappingImplementation._wrap(raw);
      /* Skipping JavaScriptCallFrame*/
      case "KeyboardEvent":
        return new KeyboardEventWrappingImplementation._wrap(raw);
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
      case "Location":
        return new LocationWrappingImplementation._wrap(raw);
      case "WebKitLoseContext":
        return new LoseContextWrappingImplementation._wrap(raw);
      case "LowPass2FilterNode":
        return new LowPass2FilterNodeWrappingImplementation._wrap(raw);
      case "HTMLMapElement":
        return new MapElementWrappingImplementation._wrap(raw);
      case "HTMLMarqueeElement":
        return new MarqueeElementWrappingImplementation._wrap(raw);
      case "HTMLMediaElement":
        return new MediaElementWrappingImplementation._wrap(raw);
      case "MediaElementAudioSourceNode":
        return new MediaElementAudioSourceNodeWrappingImplementation._wrap(raw);
      case "MediaError":
        return new MediaErrorWrappingImplementation._wrap(raw);
      case "MediaList":
        return new MediaListWrappingImplementation._wrap(raw);
      case "MediaQueryList":
        return new MediaQueryListWrappingImplementation._wrap(raw);
      case "MediaQueryListListener":
        return new MediaQueryListListenerWrappingImplementation._wrap(raw);
      /* Skipping MemoryInfo*/
      case "HTMLMenuElement":
        return new MenuElementWrappingImplementation._wrap(raw);
      case "MessageChannel":
        return new MessageChannelWrappingImplementation._wrap(raw);
      case "MessageEvent":
        return new MessageEventWrappingImplementation._wrap(raw);
      case "MessagePort":
        return new MessagePortWrappingImplementation._wrap(raw);
      case "HTMLMetaElement":
        return new MetaElementWrappingImplementation._wrap(raw);
      case "Metadata":
        return new MetadataWrappingImplementation._wrap(raw);
      /* Skipping MetadataCallback*/
      case "HTMLMeterElement":
        return new MeterElementWrappingImplementation._wrap(raw);
      case "HTMLModElement":
        return new ModElementWrappingImplementation._wrap(raw);
      case "MouseEvent":
        return new MouseEventWrappingImplementation._wrap(raw);
      case "MutationCallback":
        return new MutationCallbackWrappingImplementation._wrap(raw);
      case "MutationEvent":
        return new MutationEventWrappingImplementation._wrap(raw);
      case "MutationRecord":
        return new MutationRecordWrappingImplementation._wrap(raw);
      /* Skipping NamedNodeMap*/
      case "Navigator":
        return new NavigatorWrappingImplementation._wrap(raw);
      case "NavigatorUserMediaError":
        return new NavigatorUserMediaErrorWrappingImplementation._wrap(raw);
      /* Skipping NavigatorUserMediaErrorCallback*/
      case "NavigatorUserMediaSuccessCallback":
        return new NavigatorUserMediaSuccessCallbackWrappingImplementation._wrap(raw);
      case "Node":
        return new NodeWrappingImplementation._wrap(raw);
      /* Skipping NodeFilter*/
      /* Skipping NodeIterator*/
      /* Skipping NodeSelector*/
      case "Notation":
        return new NotationWrappingImplementation._wrap(raw);
      case "Notification":
        return new NotificationWrappingImplementation._wrap(raw);
      case "NotificationCenter":
        return new NotificationCenterWrappingImplementation._wrap(raw);
      case "OESStandardDerivatives":
        return new OESStandardDerivativesWrappingImplementation._wrap(raw);
      case "OESTextureFloat":
        return new OESTextureFloatWrappingImplementation._wrap(raw);
      case "OESVertexArrayObject":
        return new OESVertexArrayObjectWrappingImplementation._wrap(raw);
      case "HTMLOListElement":
        return new OListElementWrappingImplementation._wrap(raw);
      case "HTMLObjectElement":
        return new ObjectElementWrappingImplementation._wrap(raw);
      case "OfflineAudioCompletionEvent":
        return new OfflineAudioCompletionEventWrappingImplementation._wrap(raw);
      case "OperationNotAllowedException":
        return new OperationNotAllowedExceptionWrappingImplementation._wrap(raw);
      case "HTMLOptGroupElement":
        return new OptGroupElementWrappingImplementation._wrap(raw);
      case "HTMLOptionElement":
        return new OptionElementWrappingImplementation._wrap(raw);
      case "HTMLOutputElement":
        return new OutputElementWrappingImplementation._wrap(raw);
      case "OverflowEvent":
        return new OverflowEventWrappingImplementation._wrap(raw);
      case "PageTransitionEvent":
        return new PageTransitionEventWrappingImplementation._wrap(raw);
      case "HTMLParagraphElement":
        return new ParagraphElementWrappingImplementation._wrap(raw);
      case "HTMLParamElement":
        return new ParamElementWrappingImplementation._wrap(raw);
      /* Skipping Performance*/
      /* Skipping PerformanceNavigation*/
      /* Skipping PerformanceTiming*/
      case "WebKitPoint":
        return new PointWrappingImplementation._wrap(raw);
      case "PopStateEvent":
        return new PopStateEventWrappingImplementation._wrap(raw);
      /* Skipping PositionCallback*/
      case "PositionError":
        return new PositionErrorWrappingImplementation._wrap(raw);
      /* Skipping PositionErrorCallback*/
      case "HTMLPreElement":
        return new PreElementWrappingImplementation._wrap(raw);
      case "ProcessingInstruction":
        return new ProcessingInstructionWrappingImplementation._wrap(raw);
      case "HTMLProgressElement":
        return new ProgressElementWrappingImplementation._wrap(raw);
      case "ProgressEvent":
        return new ProgressEventWrappingImplementation._wrap(raw);
      case "HTMLQuoteElement":
        return new QuoteElementWrappingImplementation._wrap(raw);
      case "RGBColor":
        return new RGBColorWrappingImplementation._wrap(raw);
      case "Range":
        return new RangeWrappingImplementation._wrap(raw);
      case "RangeException":
        return new RangeExceptionWrappingImplementation._wrap(raw);
      case "RealtimeAnalyserNode":
        return new RealtimeAnalyserNodeWrappingImplementation._wrap(raw);
      case "Rect":
        return new RectWrappingImplementation._wrap(raw);
      /* Skipping RequestAnimationFrameCallback*/
      /* Skipping SQLError*/
      /* Skipping SQLException*/
      /* Skipping SQLResultSet*/
      /* Skipping SQLResultSetRowList*/
      /* Skipping SQLStatementCallback*/
      /* Skipping SQLStatementErrorCallback*/
      /* Skipping SQLTransaction*/
      /* Skipping SQLTransactionCallback*/
      /* Skipping SQLTransactionErrorCallback*/
      /* Skipping SQLTransactionSync*/
      /* Skipping SQLTransactionSyncCallback*/
      case "SVGAElement":
        return new SVGAElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphDefElement":
        return new SVGAltGlyphDefElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphElement":
        return new SVGAltGlyphElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphItemElement":
        return new SVGAltGlyphItemElementWrappingImplementation._wrap(raw);
      case "SVGAngle":
        return new SVGAngleWrappingImplementation._wrap(raw);
      case "SVGAnimateColorElement":
        return new SVGAnimateColorElementWrappingImplementation._wrap(raw);
      case "SVGAnimateElement":
        return new SVGAnimateElementWrappingImplementation._wrap(raw);
      case "SVGAnimateMotionElement":
        return new SVGAnimateMotionElementWrappingImplementation._wrap(raw);
      case "SVGAnimateTransformElement":
        return new SVGAnimateTransformElementWrappingImplementation._wrap(raw);
      case "SVGAnimatedAngle":
        return new SVGAnimatedAngleWrappingImplementation._wrap(raw);
      case "SVGAnimatedBoolean":
        return new SVGAnimatedBooleanWrappingImplementation._wrap(raw);
      case "SVGAnimatedEnumeration":
        return new SVGAnimatedEnumerationWrappingImplementation._wrap(raw);
      case "SVGAnimatedInteger":
        return new SVGAnimatedIntegerWrappingImplementation._wrap(raw);
      case "SVGAnimatedLength":
        return new SVGAnimatedLengthWrappingImplementation._wrap(raw);
      case "SVGAnimatedLengthList":
        return new SVGAnimatedLengthListWrappingImplementation._wrap(raw);
      case "SVGAnimatedNumber":
        return new SVGAnimatedNumberWrappingImplementation._wrap(raw);
      case "SVGAnimatedNumberList":
        return new SVGAnimatedNumberListWrappingImplementation._wrap(raw);
      case "SVGAnimatedPreserveAspectRatio":
        return new SVGAnimatedPreserveAspectRatioWrappingImplementation._wrap(raw);
      case "SVGAnimatedRect":
        return new SVGAnimatedRectWrappingImplementation._wrap(raw);
      case "SVGAnimatedString":
        return new SVGAnimatedStringWrappingImplementation._wrap(raw);
      case "SVGAnimatedTransformList":
        return new SVGAnimatedTransformListWrappingImplementation._wrap(raw);
      case "SVGAnimationElement":
        return new SVGAnimationElementWrappingImplementation._wrap(raw);
      case "SVGCircleElement":
        return new SVGCircleElementWrappingImplementation._wrap(raw);
      case "SVGClipPathElement":
        return new SVGClipPathElementWrappingImplementation._wrap(raw);
      case "SVGColor":
        return new SVGColorWrappingImplementation._wrap(raw);
      case "SVGComponentTransferFunctionElement":
        return new SVGComponentTransferFunctionElementWrappingImplementation._wrap(raw);
      case "SVGCursorElement":
        return new SVGCursorElementWrappingImplementation._wrap(raw);
      case "SVGDefsElement":
        return new SVGDefsElementWrappingImplementation._wrap(raw);
      case "SVGDescElement":
        return new SVGDescElementWrappingImplementation._wrap(raw);
      case "SVGDocument":
        return new SVGDocumentWrappingImplementation._wrap(raw);
      case "SVGElement":
        return new SVGElementWrappingImplementation._wrap(raw);
      case "SVGElementInstance":
        return new SVGElementInstanceWrappingImplementation._wrap(raw);
      case "SVGElementInstanceList":
        return new SVGElementInstanceListWrappingImplementation._wrap(raw);
      case "SVGEllipseElement":
        return new SVGEllipseElementWrappingImplementation._wrap(raw);
      case "SVGException":
        return new SVGExceptionWrappingImplementation._wrap(raw);
      case "SVGExternalResourcesRequired":
        return new SVGExternalResourcesRequiredWrappingImplementation._wrap(raw);
      case "SVGFEBlendElement":
        return new SVGFEBlendElementWrappingImplementation._wrap(raw);
      case "SVGFEColorMatrixElement":
        return new SVGFEColorMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEComponentTransferElement":
        return new SVGFEComponentTransferElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFECompositeElement*/
      case "SVGFEConvolveMatrixElement":
        return new SVGFEConvolveMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEDiffuseLightingElement":
        return new SVGFEDiffuseLightingElementWrappingImplementation._wrap(raw);
      case "SVGFEDisplacementMapElement":
        return new SVGFEDisplacementMapElementWrappingImplementation._wrap(raw);
      case "SVGFEDistantLightElement":
        return new SVGFEDistantLightElementWrappingImplementation._wrap(raw);
      case "SVGFEDropShadowElement":
        return new SVGFEDropShadowElementWrappingImplementation._wrap(raw);
      case "SVGFEFloodElement":
        return new SVGFEFloodElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncAElement":
        return new SVGFEFuncAElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncBElement":
        return new SVGFEFuncBElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncGElement":
        return new SVGFEFuncGElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncRElement":
        return new SVGFEFuncRElementWrappingImplementation._wrap(raw);
      case "SVGFEGaussianBlurElement":
        return new SVGFEGaussianBlurElementWrappingImplementation._wrap(raw);
      case "SVGFEImageElement":
        return new SVGFEImageElementWrappingImplementation._wrap(raw);
      case "SVGFEMergeElement":
        return new SVGFEMergeElementWrappingImplementation._wrap(raw);
      case "SVGFEMergeNodeElement":
        return new SVGFEMergeNodeElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFEMorphologyElement*/
      case "SVGFEOffsetElement":
        return new SVGFEOffsetElementWrappingImplementation._wrap(raw);
      case "SVGFEPointLightElement":
        return new SVGFEPointLightElementWrappingImplementation._wrap(raw);
      case "SVGFESpecularLightingElement":
        return new SVGFESpecularLightingElementWrappingImplementation._wrap(raw);
      case "SVGFESpotLightElement":
        return new SVGFESpotLightElementWrappingImplementation._wrap(raw);
      case "SVGFETileElement":
        return new SVGFETileElementWrappingImplementation._wrap(raw);
      case "SVGFETurbulenceElement":
        return new SVGFETurbulenceElementWrappingImplementation._wrap(raw);
      case "SVGFilterElement":
        return new SVGFilterElementWrappingImplementation._wrap(raw);
      case "SVGFilterPrimitiveStandardAttributes":
        return new SVGFilterPrimitiveStandardAttributesWrappingImplementation._wrap(raw);
      case "SVGFitToViewBox":
        return new SVGFitToViewBoxWrappingImplementation._wrap(raw);
      case "SVGFontElement":
        return new SVGFontElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceElement":
        return new SVGFontFaceElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceFormatElement":
        return new SVGFontFaceFormatElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceNameElement":
        return new SVGFontFaceNameElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceSrcElement":
        return new SVGFontFaceSrcElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceUriElement":
        return new SVGFontFaceUriElementWrappingImplementation._wrap(raw);
      case "SVGForeignObjectElement":
        return new SVGForeignObjectElementWrappingImplementation._wrap(raw);
      case "SVGGElement":
        return new SVGGElementWrappingImplementation._wrap(raw);
      case "SVGGlyphElement":
        return new SVGGlyphElementWrappingImplementation._wrap(raw);
      case "SVGGlyphRefElement":
        return new SVGGlyphRefElementWrappingImplementation._wrap(raw);
      case "SVGGradientElement":
        return new SVGGradientElementWrappingImplementation._wrap(raw);
      case "SVGHKernElement":
        return new SVGHKernElementWrappingImplementation._wrap(raw);
      case "SVGImageElement":
        return new SVGImageElementWrappingImplementation._wrap(raw);
      case "SVGLangSpace":
        return new SVGLangSpaceWrappingImplementation._wrap(raw);
      case "SVGLength":
        return new SVGLengthWrappingImplementation._wrap(raw);
      case "SVGLengthList":
        return new SVGLengthListWrappingImplementation._wrap(raw);
      case "SVGLineElement":
        return new SVGLineElementWrappingImplementation._wrap(raw);
      case "SVGLinearGradientElement":
        return new SVGLinearGradientElementWrappingImplementation._wrap(raw);
      case "SVGLocatable":
        return new SVGLocatableWrappingImplementation._wrap(raw);
      case "SVGMPathElement":
        return new SVGMPathElementWrappingImplementation._wrap(raw);
      case "SVGMarkerElement":
        return new SVGMarkerElementWrappingImplementation._wrap(raw);
      case "SVGMaskElement":
        return new SVGMaskElementWrappingImplementation._wrap(raw);
      case "SVGMatrix":
        return new SVGMatrixWrappingImplementation._wrap(raw);
      case "SVGMetadataElement":
        return new SVGMetadataElementWrappingImplementation._wrap(raw);
      case "SVGMissingGlyphElement":
        return new SVGMissingGlyphElementWrappingImplementation._wrap(raw);
      case "SVGNumber":
        return new SVGNumberWrappingImplementation._wrap(raw);
      case "SVGNumberList":
        return new SVGNumberListWrappingImplementation._wrap(raw);
      case "SVGPaint":
        return new SVGPaintWrappingImplementation._wrap(raw);
      case "SVGPathElement":
        return new SVGPathElementWrappingImplementation._wrap(raw);
      case "SVGPathSeg":
        return new SVGPathSegWrappingImplementation._wrap(raw);
      case "SVGPathSegArcAbs":
        return new SVGPathSegArcAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegArcRel":
        return new SVGPathSegArcRelWrappingImplementation._wrap(raw);
      case "SVGPathSegClosePath":
        return new SVGPathSegClosePathWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoCubicAbs":
        return new SVGPathSegCurvetoCubicAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoCubicRel":
        return new SVGPathSegCurvetoCubicRelWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoCubicSmoothAbs":
        return new SVGPathSegCurvetoCubicSmoothAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoCubicSmoothRel":
        return new SVGPathSegCurvetoCubicSmoothRelWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoQuadraticAbs":
        return new SVGPathSegCurvetoQuadraticAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoQuadraticRel":
        return new SVGPathSegCurvetoQuadraticRelWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoQuadraticSmoothAbs":
        return new SVGPathSegCurvetoQuadraticSmoothAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoQuadraticSmoothRel":
        return new SVGPathSegCurvetoQuadraticSmoothRelWrappingImplementation._wrap(raw);
      case "SVGPathSegLinetoAbs":
        return new SVGPathSegLinetoAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegLinetoHorizontalAbs":
        return new SVGPathSegLinetoHorizontalAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegLinetoHorizontalRel":
        return new SVGPathSegLinetoHorizontalRelWrappingImplementation._wrap(raw);
      case "SVGPathSegLinetoRel":
        return new SVGPathSegLinetoRelWrappingImplementation._wrap(raw);
      case "SVGPathSegLinetoVerticalAbs":
        return new SVGPathSegLinetoVerticalAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegLinetoVerticalRel":
        return new SVGPathSegLinetoVerticalRelWrappingImplementation._wrap(raw);
      case "SVGPathSegList":
        return new SVGPathSegListWrappingImplementation._wrap(raw);
      case "SVGPathSegMovetoAbs":
        return new SVGPathSegMovetoAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegMovetoRel":
        return new SVGPathSegMovetoRelWrappingImplementation._wrap(raw);
      case "SVGPatternElement":
        return new SVGPatternElementWrappingImplementation._wrap(raw);
      case "SVGPoint":
        return new SVGPointWrappingImplementation._wrap(raw);
      case "SVGPointList":
        return new SVGPointListWrappingImplementation._wrap(raw);
      case "SVGPolygonElement":
        return new SVGPolygonElementWrappingImplementation._wrap(raw);
      case "SVGPolylineElement":
        return new SVGPolylineElementWrappingImplementation._wrap(raw);
      case "SVGPreserveAspectRatio":
        return new SVGPreserveAspectRatioWrappingImplementation._wrap(raw);
      case "SVGRadialGradientElement":
        return new SVGRadialGradientElementWrappingImplementation._wrap(raw);
      case "SVGRect":
        return new SVGRectWrappingImplementation._wrap(raw);
      case "SVGRectElement":
        return new SVGRectElementWrappingImplementation._wrap(raw);
      case "SVGRenderingIntent":
        return new SVGRenderingIntentWrappingImplementation._wrap(raw);
      case "SVGSVGElement":
        return new SVGSVGElementWrappingImplementation._wrap(raw);
      case "SVGScriptElement":
        return new SVGScriptElementWrappingImplementation._wrap(raw);
      case "SVGSetElement":
        return new SVGSetElementWrappingImplementation._wrap(raw);
      case "SVGStopElement":
        return new SVGStopElementWrappingImplementation._wrap(raw);
      case "SVGStringList":
        return new SVGStringListWrappingImplementation._wrap(raw);
      case "SVGStylable":
        return new SVGStylableWrappingImplementation._wrap(raw);
      case "SVGStyleElement":
        return new SVGStyleElementWrappingImplementation._wrap(raw);
      case "SVGSwitchElement":
        return new SVGSwitchElementWrappingImplementation._wrap(raw);
      case "SVGSymbolElement":
        return new SVGSymbolElementWrappingImplementation._wrap(raw);
      case "SVGTRefElement":
        return new SVGTRefElementWrappingImplementation._wrap(raw);
      case "SVGTSpanElement":
        return new SVGTSpanElementWrappingImplementation._wrap(raw);
      case "SVGTests":
        return new SVGTestsWrappingImplementation._wrap(raw);
      case "SVGTextContentElement":
        return new SVGTextContentElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTextPathElement":
        return new SVGTextPathElementWrappingImplementation._wrap(raw);
      case "SVGTextPositioningElement":
        return new SVGTextPositioningElementWrappingImplementation._wrap(raw);
      case "SVGTitleElement":
        return new SVGTitleElementWrappingImplementation._wrap(raw);
      case "SVGTransform":
        return new SVGTransformWrappingImplementation._wrap(raw);
      case "SVGTransformList":
        return new SVGTransformListWrappingImplementation._wrap(raw);
      case "SVGTransformable":
        return new SVGTransformableWrappingImplementation._wrap(raw);
      case "SVGURIReference":
        return new SVGURIReferenceWrappingImplementation._wrap(raw);
      case "SVGUnitTypes":
        return new SVGUnitTypesWrappingImplementation._wrap(raw);
      case "SVGUseElement":
        return new SVGUseElementWrappingImplementation._wrap(raw);
      case "SVGVKernElement":
        return new SVGVKernElementWrappingImplementation._wrap(raw);
      case "SVGViewElement":
        return new SVGViewElementWrappingImplementation._wrap(raw);
      case "SVGViewSpec":
        return new SVGViewSpecWrappingImplementation._wrap(raw);
      case "SVGZoomAndPan":
        return new SVGZoomAndPanWrappingImplementation._wrap(raw);
      case "SVGZoomEvent":
        return new SVGZoomEventWrappingImplementation._wrap(raw);
      case "Screen":
        return new ScreenWrappingImplementation._wrap(raw);
      case "HTMLScriptElement":
        return new ScriptElementWrappingImplementation._wrap(raw);
      /* Skipping ScriptProfile*/
      /* Skipping ScriptProfileNode*/
      case "HTMLSelectElement":
        return new SelectElementWrappingImplementation._wrap(raw);
      case "SharedWorker":
        return new SharedWorkerWrappingImplementation._wrap(raw);
      /* Skipping SharedWorkercontext*/
      case "HTMLSourceElement":
        return new SourceElementWrappingImplementation._wrap(raw);
      case "HTMLSpanElement":
        return new SpanElementWrappingImplementation._wrap(raw);
      case "SpeechInputEvent":
        return new SpeechInputEventWrappingImplementation._wrap(raw);
      case "SpeechInputResult":
        return new SpeechInputResultWrappingImplementation._wrap(raw);
      case "SpeechInputResultList":
        return new SpeechInputResultListWrappingImplementation._wrap(raw);
      case "Storage":
        return new StorageWrappingImplementation._wrap(raw);
      case "StorageEvent":
        return new StorageEventWrappingImplementation._wrap(raw);
      case "StorageInfo":
        return new StorageInfoWrappingImplementation._wrap(raw);
      /* Skipping StorageInfoErrorCallback*/
      /* Skipping StorageInfoQuotaCallback*/
      /* Skipping StorageInfoUsageCallback*/
      /* Skipping StringCallback*/
      case "HTMLStyleElement":
        return new StyleElementWrappingImplementation._wrap(raw);
      case "StyleMedia":
        return new StyleMediaWrappingImplementation._wrap(raw);
      case "StyleSheet":
        return new StyleSheetWrappingImplementation._wrap(raw);
      case "StyleSheetList":
        return new StyleSheetListWrappingImplementation._wrap(raw);
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
      case "TextEvent":
        return new TextEventWrappingImplementation._wrap(raw);
      case "TextMetrics":
        return new TextMetricsWrappingImplementation._wrap(raw);
      case "TextTrack":
        return new TextTrackWrappingImplementation._wrap(raw);
      case "TextTrackCue":
        return new TextTrackCueWrappingImplementation._wrap(raw);
      case "TextTrackCueList":
        return new TextTrackCueListWrappingImplementation._wrap(raw);
      case "TimeRanges":
        return new TimeRangesWrappingImplementation._wrap(raw);
      case "HTMLTitleElement":
        return new TitleElementWrappingImplementation._wrap(raw);
      case "Touch":
        return new TouchWrappingImplementation._wrap(raw);
      case "TouchEvent":
        return new TouchEventWrappingImplementation._wrap(raw);
      case "TouchList":
        return new TouchListWrappingImplementation._wrap(raw);
      case "HTMLTrackElement":
        return new TrackElementWrappingImplementation._wrap(raw);
      case "WebKitTransitionEvent":
        return new TransitionEventWrappingImplementation._wrap(raw);
      /* Skipping TreeWalker*/
      case "UIEvent":
        return new UIEventWrappingImplementation._wrap(raw);
      case "HTMLUListElement":
        return new UListElementWrappingImplementation._wrap(raw);
      case "Uint16Array":
        return new Uint16ArrayWrappingImplementation._wrap(raw);
      case "Uint32Array":
        return new Uint32ArrayWrappingImplementation._wrap(raw);
      case "Uint8Array":
        return new Uint8ArrayWrappingImplementation._wrap(raw);
      case "HTMLUnknownElement":
        return new UnknownElementWrappingImplementation._wrap(raw);
      case "ValidityState":
        return new ValidityStateWrappingImplementation._wrap(raw);
      case "HTMLVideoElement":
        return new VideoElementWrappingImplementation._wrap(raw);
      case "VoidCallback":
        return new VoidCallbackWrappingImplementation._wrap(raw);
      case "WaveShaperNode":
        return new WaveShaperNodeWrappingImplementation._wrap(raw);
      case "WebGLActiveInfo":
        return new WebGLActiveInfoWrappingImplementation._wrap(raw);
      case "WebGLBuffer":
        return new WebGLBufferWrappingImplementation._wrap(raw);
      case "WebGLContextAttributes":
        return new WebGLContextAttributesWrappingImplementation._wrap(raw);
      case "WebGLContextEvent":
        return new WebGLContextEventWrappingImplementation._wrap(raw);
      case "WebGLDebugRendererInfo":
        return new WebGLDebugRendererInfoWrappingImplementation._wrap(raw);
      case "WebGLDebugShaders":
        return new WebGLDebugShadersWrappingImplementation._wrap(raw);
      case "WebGLFramebuffer":
        return new WebGLFramebufferWrappingImplementation._wrap(raw);
      case "WebGLProgram":
        return new WebGLProgramWrappingImplementation._wrap(raw);
      case "WebGLRenderbuffer":
        return new WebGLRenderbufferWrappingImplementation._wrap(raw);
      case "WebGLRenderingContext":
        return new WebGLRenderingContextWrappingImplementation._wrap(raw);
      case "WebGLShader":
        return new WebGLShaderWrappingImplementation._wrap(raw);
      case "WebGLTexture":
        return new WebGLTextureWrappingImplementation._wrap(raw);
      case "WebGLUniformLocation":
        return new WebGLUniformLocationWrappingImplementation._wrap(raw);
      case "WebGLVertexArrayObjectOES":
        return new WebGLVertexArrayObjectOESWrappingImplementation._wrap(raw);
      case "WebKitCSSFilterValue":
        return new WebKitCSSFilterValueWrappingImplementation._wrap(raw);
      case "WebKitMutationObserver":
        return new WebKitMutationObserverWrappingImplementation._wrap(raw);
      case "WebSocket":
        return new WebSocketWrappingImplementation._wrap(raw);
      case "WheelEvent":
        return new WheelEventWrappingImplementation._wrap(raw);
      case "Window":
        return new WindowWrappingImplementation._wrap(raw);
      case "Worker":
        return new WorkerWrappingImplementation._wrap(raw);
      /* Skipping WorkerContext*/
      /* Skipping WorkerLocation*/
      /* Skipping WorkerNavigator*/
      case "XMLHttpRequest":
        return new XMLHttpRequestWrappingImplementation._wrap(raw);
      case "XMLHttpRequestException":
        return new XMLHttpRequestExceptionWrappingImplementation._wrap(raw);
      case "XMLHttpRequestProgressEvent":
        return new XMLHttpRequestProgressEventWrappingImplementation._wrap(raw);
      case "XMLHttpRequestUpload":
        return new XMLHttpRequestUploadWrappingImplementation._wrap(raw);
      /* Skipping XMLSerializer*/
      /* Skipping XPathEvaluator*/
      /* Skipping XPathException*/
      /* Skipping XPathExpression*/
      /* Skipping XPathNSResolver*/
      /* Skipping XPathResult*/
      /* Skipping XSLTProcessor*/
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static unwrapMaybePrimitive(raw) {
    return (raw === null || raw is String || raw is num || raw is bool) ? raw : raw._ptr;
  }

  static unwrap(raw) {
    return raw === null ? null : raw._ptr;
  }


  static void initialize() {
    secretWindow = wrapWindow(dom.window);
    secretDocument = wrapDocument(dom.document);
  }

}
