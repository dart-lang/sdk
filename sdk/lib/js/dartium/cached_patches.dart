// START_OF_CACHED_PATCHES
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT GENERATED FILE.

library cached_patches;

var cached_patches = {
  "dart:html": [
    "dart:html",
    "dart:html_js_interop_patch.dart",
    """import 'dart:js' as js_library;

/**
 * Placeholder object for cases where we need to determine exactly how many
 * args were passed to a function.
 */
const _UNDEFINED_JS_CONST = const Object();

@patch class AbstractWorker {
  static Type get instanceRuntimeType => AbstractWorkerImpl;

}
class AbstractWorkerImpl extends AbstractWorker implements js_library.JSObjectInterfacesDom {
  AbstractWorkerImpl.internal_() : super.internal_();
  get runtimeType => AbstractWorker;
  toString() => super.toString();
}
@patch class AnchorElement {
  static Type get instanceRuntimeType => AnchorElementImpl;

}
class AnchorElementImpl extends AnchorElement implements js_library.JSObjectInterfacesDom {
  AnchorElementImpl.internal_() : super.internal_();
  get runtimeType => AnchorElement;
  toString() => super.toString();
}
@patch class Animation {
  static Type get instanceRuntimeType => AnimationImpl;

}
class AnimationImpl extends Animation implements js_library.JSObjectInterfacesDom {
  AnimationImpl.internal_() : super.internal_();
  get runtimeType => Animation;
  toString() => super.toString();
}
@patch class AnimationEffectReadOnly {
  static Type get instanceRuntimeType => AnimationEffectReadOnlyImpl;

}
class AnimationEffectReadOnlyImpl extends AnimationEffectReadOnly implements js_library.JSObjectInterfacesDom {
  AnimationEffectReadOnlyImpl.internal_() : super.internal_();
  get runtimeType => AnimationEffectReadOnly;
  toString() => super.toString();
}
@patch class AnimationEffectTiming {
  static Type get instanceRuntimeType => AnimationEffectTimingImpl;

}
class AnimationEffectTimingImpl extends AnimationEffectTiming implements js_library.JSObjectInterfacesDom {
  AnimationEffectTimingImpl.internal_() : super.internal_();
  get runtimeType => AnimationEffectTiming;
  toString() => super.toString();
}
@patch class AnimationEvent {
  static Type get instanceRuntimeType => AnimationEventImpl;

}
class AnimationEventImpl extends AnimationEvent implements js_library.JSObjectInterfacesDom {
  AnimationEventImpl.internal_() : super.internal_();
  get runtimeType => AnimationEvent;
  toString() => super.toString();
}
@patch class AnimationPlayerEvent {
  static Type get instanceRuntimeType => AnimationPlayerEventImpl;

}
class AnimationPlayerEventImpl extends AnimationPlayerEvent implements js_library.JSObjectInterfacesDom {
  AnimationPlayerEventImpl.internal_() : super.internal_();
  get runtimeType => AnimationPlayerEvent;
  toString() => super.toString();
}
@patch class AnimationTimeline {
  static Type get instanceRuntimeType => AnimationTimelineImpl;

}
class AnimationTimelineImpl extends AnimationTimeline implements js_library.JSObjectInterfacesDom {
  AnimationTimelineImpl.internal_() : super.internal_();
  get runtimeType => AnimationTimeline;
  toString() => super.toString();
}
@patch class AppBannerPromptResult {
  static Type get instanceRuntimeType => AppBannerPromptResultImpl;

}
class AppBannerPromptResultImpl extends AppBannerPromptResult implements js_library.JSObjectInterfacesDom {
  AppBannerPromptResultImpl.internal_() : super.internal_();
  get runtimeType => AppBannerPromptResult;
  toString() => super.toString();
}
@patch class ApplicationCache {
  static Type get instanceRuntimeType => ApplicationCacheImpl;

}
class ApplicationCacheImpl extends ApplicationCache implements js_library.JSObjectInterfacesDom {
  ApplicationCacheImpl.internal_() : super.internal_();
  get runtimeType => ApplicationCache;
  toString() => super.toString();
}
@patch class ApplicationCacheErrorEvent {
  static Type get instanceRuntimeType => ApplicationCacheErrorEventImpl;

}
class ApplicationCacheErrorEventImpl extends ApplicationCacheErrorEvent implements js_library.JSObjectInterfacesDom {
  ApplicationCacheErrorEventImpl.internal_() : super.internal_();
  get runtimeType => ApplicationCacheErrorEvent;
  toString() => super.toString();
}
@patch class AreaElement {
  static Type get instanceRuntimeType => AreaElementImpl;

}
class AreaElementImpl extends AreaElement implements js_library.JSObjectInterfacesDom {
  AreaElementImpl.internal_() : super.internal_();
  get runtimeType => AreaElement;
  toString() => super.toString();
}
@patch class AudioElement {
  static Type get instanceRuntimeType => AudioElementImpl;

}
class AudioElementImpl extends AudioElement implements js_library.JSObjectInterfacesDom {
  AudioElementImpl.internal_() : super.internal_();
  get runtimeType => AudioElement;
  toString() => super.toString();
}
@patch class AudioTrack {
  static Type get instanceRuntimeType => AudioTrackImpl;

}
class AudioTrackImpl extends AudioTrack implements js_library.JSObjectInterfacesDom {
  AudioTrackImpl.internal_() : super.internal_();
  get runtimeType => AudioTrack;
  toString() => super.toString();
}
@patch class AudioTrackList {
  static Type get instanceRuntimeType => AudioTrackListImpl;

}
class AudioTrackListImpl extends AudioTrackList implements js_library.JSObjectInterfacesDom {
  AudioTrackListImpl.internal_() : super.internal_();
  get runtimeType => AudioTrackList;
  toString() => super.toString();
}
@patch class AutocompleteErrorEvent {
  static Type get instanceRuntimeType => AutocompleteErrorEventImpl;

}
class AutocompleteErrorEventImpl extends AutocompleteErrorEvent implements js_library.JSObjectInterfacesDom {
  AutocompleteErrorEventImpl.internal_() : super.internal_();
  get runtimeType => AutocompleteErrorEvent;
  toString() => super.toString();
}
@patch class BRElement {
  static Type get instanceRuntimeType => BRElementImpl;

}
class BRElementImpl extends BRElement implements js_library.JSObjectInterfacesDom {
  BRElementImpl.internal_() : super.internal_();
  get runtimeType => BRElement;
  toString() => super.toString();
}
@patch class BarProp {
  static Type get instanceRuntimeType => BarPropImpl;

}
class BarPropImpl extends BarProp implements js_library.JSObjectInterfacesDom {
  BarPropImpl.internal_() : super.internal_();
  get runtimeType => BarProp;
  toString() => super.toString();
}
@patch class BaseElement {
  static Type get instanceRuntimeType => BaseElementImpl;

}
class BaseElementImpl extends BaseElement implements js_library.JSObjectInterfacesDom {
  BaseElementImpl.internal_() : super.internal_();
  get runtimeType => BaseElement;
  toString() => super.toString();
}
@patch class BatteryManager {
  static Type get instanceRuntimeType => BatteryManagerImpl;

}
class BatteryManagerImpl extends BatteryManager implements js_library.JSObjectInterfacesDom {
  BatteryManagerImpl.internal_() : super.internal_();
  get runtimeType => BatteryManager;
  toString() => super.toString();
}
@patch class BeforeInstallPromptEvent {
  static Type get instanceRuntimeType => BeforeInstallPromptEventImpl;

}
class BeforeInstallPromptEventImpl extends BeforeInstallPromptEvent implements js_library.JSObjectInterfacesDom {
  BeforeInstallPromptEventImpl.internal_() : super.internal_();
  get runtimeType => BeforeInstallPromptEvent;
  toString() => super.toString();
}
@patch class BeforeUnloadEvent {
  static Type get instanceRuntimeType => BeforeUnloadEventImpl;

}
class BeforeUnloadEventImpl extends BeforeUnloadEvent implements js_library.JSObjectInterfacesDom {
  BeforeUnloadEventImpl.internal_() : super.internal_();
  get runtimeType => BeforeUnloadEvent;
  toString() => super.toString();
}
@patch class Blob {
  static Type get instanceRuntimeType => BlobImpl;

}
class BlobImpl extends Blob implements js_library.JSObjectInterfacesDom {
  BlobImpl.internal_() : super.internal_();
  get runtimeType => Blob;
  toString() => super.toString();
}
@patch class BlobEvent {
  static Type get instanceRuntimeType => BlobEventImpl;

}
class BlobEventImpl extends BlobEvent implements js_library.JSObjectInterfacesDom {
  BlobEventImpl.internal_() : super.internal_();
  get runtimeType => BlobEvent;
  toString() => super.toString();
}
@patch class Body {
  static Type get instanceRuntimeType => BodyImpl;

}
class BodyImpl extends Body implements js_library.JSObjectInterfacesDom {
  BodyImpl.internal_() : super.internal_();
  get runtimeType => Body;
  toString() => super.toString();
}
@patch class BodyElement {
  static Type get instanceRuntimeType => BodyElementImpl;

}
class BodyElementImpl extends BodyElement implements js_library.JSObjectInterfacesDom {
  BodyElementImpl.internal_() : super.internal_();
  get runtimeType => BodyElement;
  toString() => super.toString();
}
@patch class ButtonElement {
  static Type get instanceRuntimeType => ButtonElementImpl;

}
class ButtonElementImpl extends ButtonElement implements js_library.JSObjectInterfacesDom {
  ButtonElementImpl.internal_() : super.internal_();
  get runtimeType => ButtonElement;
  toString() => super.toString();
}
@patch class CDataSection {
  static Type get instanceRuntimeType => CDataSectionImpl;

}
class CDataSectionImpl extends CDataSection implements js_library.JSObjectInterfacesDom {
  CDataSectionImpl.internal_() : super.internal_();
  get runtimeType => CDataSection;
  toString() => super.toString();
}
@patch class CacheStorage {
  static Type get instanceRuntimeType => CacheStorageImpl;

}
class CacheStorageImpl extends CacheStorage implements js_library.JSObjectInterfacesDom {
  CacheStorageImpl.internal_() : super.internal_();
  get runtimeType => CacheStorage;
  toString() => super.toString();
}
@patch class CalcLength {
  static Type get instanceRuntimeType => CalcLengthImpl;

}
class CalcLengthImpl extends CalcLength implements js_library.JSObjectInterfacesDom {
  CalcLengthImpl.internal_() : super.internal_();
  get runtimeType => CalcLength;
  toString() => super.toString();
}
@patch class CanvasCaptureMediaStreamTrack {
  static Type get instanceRuntimeType => CanvasCaptureMediaStreamTrackImpl;

}
class CanvasCaptureMediaStreamTrackImpl extends CanvasCaptureMediaStreamTrack implements js_library.JSObjectInterfacesDom {
  CanvasCaptureMediaStreamTrackImpl.internal_() : super.internal_();
  get runtimeType => CanvasCaptureMediaStreamTrack;
  toString() => super.toString();
}
@patch class CanvasElement {
  static Type get instanceRuntimeType => CanvasElementImpl;

}
class CanvasElementImpl extends CanvasElement implements js_library.JSObjectInterfacesDom {
  CanvasElementImpl.internal_() : super.internal_();
  get runtimeType => CanvasElement;
  toString() => super.toString();
}
@patch class CanvasGradient {
  static Type get instanceRuntimeType => CanvasGradientImpl;

}
class CanvasGradientImpl extends CanvasGradient implements js_library.JSObjectInterfacesDom {
  CanvasGradientImpl.internal_() : super.internal_();
  get runtimeType => CanvasGradient;
  toString() => super.toString();
}
@patch class CanvasPattern {
  static Type get instanceRuntimeType => CanvasPatternImpl;

}
class CanvasPatternImpl extends CanvasPattern implements js_library.JSObjectInterfacesDom {
  CanvasPatternImpl.internal_() : super.internal_();
  get runtimeType => CanvasPattern;
  toString() => super.toString();
}
@patch class CanvasRenderingContext2D {
  static Type get instanceRuntimeType => CanvasRenderingContext2DImpl;

}
class CanvasRenderingContext2DImpl extends CanvasRenderingContext2D implements js_library.JSObjectInterfacesDom {
  CanvasRenderingContext2DImpl.internal_() : super.internal_();
  get runtimeType => CanvasRenderingContext2D;
  toString() => super.toString();
}
@patch class CharacterData {
  static Type get instanceRuntimeType => CharacterDataImpl;

}
class CharacterDataImpl extends CharacterData implements js_library.JSObjectInterfacesDom {
  CharacterDataImpl.internal_() : super.internal_();
  get runtimeType => CharacterData;
  toString() => super.toString();
}
@patch class ChildNode {
  static Type get instanceRuntimeType => ChildNodeImpl;

}
class ChildNodeImpl extends ChildNode implements js_library.JSObjectInterfacesDom {
  ChildNodeImpl.internal_() : super.internal_();
  get runtimeType => ChildNode;
  toString() => super.toString();
}
@patch class ChromiumValuebuffer {
  static Type get instanceRuntimeType => ChromiumValuebufferImpl;

}
class ChromiumValuebufferImpl extends ChromiumValuebuffer implements js_library.JSObjectInterfacesDom {
  ChromiumValuebufferImpl.internal_() : super.internal_();
  get runtimeType => ChromiumValuebuffer;
  toString() => super.toString();
}
@patch class CircularGeofencingRegion {
  static Type get instanceRuntimeType => CircularGeofencingRegionImpl;

}
class CircularGeofencingRegionImpl extends CircularGeofencingRegion implements js_library.JSObjectInterfacesDom {
  CircularGeofencingRegionImpl.internal_() : super.internal_();
  get runtimeType => CircularGeofencingRegion;
  toString() => super.toString();
}
@patch class Client {
  static Type get instanceRuntimeType => ClientImpl;

}
class ClientImpl extends Client implements js_library.JSObjectInterfacesDom {
  ClientImpl.internal_() : super.internal_();
  get runtimeType => Client;
  toString() => super.toString();
}
@patch class Clients {
  static Type get instanceRuntimeType => ClientsImpl;

}
class ClientsImpl extends Clients implements js_library.JSObjectInterfacesDom {
  ClientsImpl.internal_() : super.internal_();
  get runtimeType => Clients;
  toString() => super.toString();
}
@patch class ClipboardEvent {
  static Type get instanceRuntimeType => ClipboardEventImpl;

}
class ClipboardEventImpl extends ClipboardEvent implements js_library.JSObjectInterfacesDom {
  ClipboardEventImpl.internal_() : super.internal_();
  get runtimeType => ClipboardEvent;
  toString() => super.toString();
}
@patch class CloseEvent {
  static Type get instanceRuntimeType => CloseEventImpl;

}
class CloseEventImpl extends CloseEvent implements js_library.JSObjectInterfacesDom {
  CloseEventImpl.internal_() : super.internal_();
  get runtimeType => CloseEvent;
  toString() => super.toString();
}
@patch class Comment {
  static Type get instanceRuntimeType => CommentImpl;

}
class CommentImpl extends Comment implements js_library.JSObjectInterfacesDom {
  CommentImpl.internal_() : super.internal_();
  get runtimeType => Comment;
  toString() => super.toString();
}
@patch class CompositionEvent {
  static Type get instanceRuntimeType => CompositionEventImpl;

}
class CompositionEventImpl extends CompositionEvent implements js_library.JSObjectInterfacesDom {
  CompositionEventImpl.internal_() : super.internal_();
  get runtimeType => CompositionEvent;
  toString() => super.toString();
}
@patch class CompositorProxy {
  static Type get instanceRuntimeType => CompositorProxyImpl;

}
class CompositorProxyImpl extends CompositorProxy implements js_library.JSObjectInterfacesDom {
  CompositorProxyImpl.internal_() : super.internal_();
  get runtimeType => CompositorProxy;
  toString() => super.toString();
}
@patch class CompositorWorker {
  static Type get instanceRuntimeType => CompositorWorkerImpl;

}
class CompositorWorkerImpl extends CompositorWorker implements js_library.JSObjectInterfacesDom {
  CompositorWorkerImpl.internal_() : super.internal_();
  get runtimeType => CompositorWorker;
  toString() => super.toString();
}
@patch class CompositorWorkerGlobalScope {
  static Type get instanceRuntimeType => CompositorWorkerGlobalScopeImpl;

}
class CompositorWorkerGlobalScopeImpl extends CompositorWorkerGlobalScope implements js_library.JSObjectInterfacesDom {
  CompositorWorkerGlobalScopeImpl.internal_() : super.internal_();
  get runtimeType => CompositorWorkerGlobalScope;
  toString() => super.toString();
}
@patch class Console {
  static Type get instanceRuntimeType => ConsoleImpl;

}
class ConsoleImpl extends Console implements js_library.JSObjectInterfacesDom {
  ConsoleImpl.internal_() : super.internal_();
  get runtimeType => Console;
  toString() => super.toString();
}
@patch class ConsoleBase {
  static Type get instanceRuntimeType => ConsoleBaseImpl;

}
class ConsoleBaseImpl extends ConsoleBase implements js_library.JSObjectInterfacesDom {
  ConsoleBaseImpl.internal_() : super.internal_();
  get runtimeType => ConsoleBase;
  toString() => super.toString();
}
@patch class ContentElement {
  static Type get instanceRuntimeType => ContentElementImpl;

}
class ContentElementImpl extends ContentElement implements js_library.JSObjectInterfacesDom {
  ContentElementImpl.internal_() : super.internal_();
  get runtimeType => ContentElement;
  toString() => super.toString();
}
@patch class Coordinates {
  static Type get instanceRuntimeType => CoordinatesImpl;

}
class CoordinatesImpl extends Coordinates implements js_library.JSObjectInterfacesDom {
  CoordinatesImpl.internal_() : super.internal_();
  get runtimeType => Coordinates;
  toString() => super.toString();
}
@patch class Credential {
  static Type get instanceRuntimeType => CredentialImpl;

}
class CredentialImpl extends Credential implements js_library.JSObjectInterfacesDom {
  CredentialImpl.internal_() : super.internal_();
  get runtimeType => Credential;
  toString() => super.toString();
}
@patch class CredentialsContainer {
  static Type get instanceRuntimeType => CredentialsContainerImpl;

}
class CredentialsContainerImpl extends CredentialsContainer implements js_library.JSObjectInterfacesDom {
  CredentialsContainerImpl.internal_() : super.internal_();
  get runtimeType => CredentialsContainer;
  toString() => super.toString();
}
@patch class CrossOriginServiceWorkerClient {
  static Type get instanceRuntimeType => CrossOriginServiceWorkerClientImpl;

}
class CrossOriginServiceWorkerClientImpl extends CrossOriginServiceWorkerClient implements js_library.JSObjectInterfacesDom {
  CrossOriginServiceWorkerClientImpl.internal_() : super.internal_();
  get runtimeType => CrossOriginServiceWorkerClient;
  toString() => super.toString();
}
@patch class Crypto {
  static Type get instanceRuntimeType => CryptoImpl;

}
class CryptoImpl extends Crypto implements js_library.JSObjectInterfacesDom {
  CryptoImpl.internal_() : super.internal_();
  get runtimeType => Crypto;
  toString() => super.toString();
}
@patch class CryptoKey {
  static Type get instanceRuntimeType => CryptoKeyImpl;

}
class CryptoKeyImpl extends CryptoKey implements js_library.JSObjectInterfacesDom {
  CryptoKeyImpl.internal_() : super.internal_();
  get runtimeType => CryptoKey;
  toString() => super.toString();
}
@patch class Css {
  static Type get instanceRuntimeType => CssImpl;

}
class CssImpl extends Css implements js_library.JSObjectInterfacesDom {
  CssImpl.internal_() : super.internal_();
  get runtimeType => Css;
  toString() => super.toString();
}
@patch class CssCharsetRule {
  static Type get instanceRuntimeType => CssCharsetRuleImpl;

}
class CssCharsetRuleImpl extends CssCharsetRule implements js_library.JSObjectInterfacesDom {
  CssCharsetRuleImpl.internal_() : super.internal_();
  get runtimeType => CssCharsetRule;
  toString() => super.toString();
}
@patch class CssFontFaceRule {
  static Type get instanceRuntimeType => CssFontFaceRuleImpl;

}
class CssFontFaceRuleImpl extends CssFontFaceRule implements js_library.JSObjectInterfacesDom {
  CssFontFaceRuleImpl.internal_() : super.internal_();
  get runtimeType => CssFontFaceRule;
  toString() => super.toString();
}
@patch class CssGroupingRule {
  static Type get instanceRuntimeType => CssGroupingRuleImpl;

}
class CssGroupingRuleImpl extends CssGroupingRule implements js_library.JSObjectInterfacesDom {
  CssGroupingRuleImpl.internal_() : super.internal_();
  get runtimeType => CssGroupingRule;
  toString() => super.toString();
}
@patch class CssImportRule {
  static Type get instanceRuntimeType => CssImportRuleImpl;

}
class CssImportRuleImpl extends CssImportRule implements js_library.JSObjectInterfacesDom {
  CssImportRuleImpl.internal_() : super.internal_();
  get runtimeType => CssImportRule;
  toString() => super.toString();
}
@patch class CssKeyframeRule {
  static Type get instanceRuntimeType => CssKeyframeRuleImpl;

}
class CssKeyframeRuleImpl extends CssKeyframeRule implements js_library.JSObjectInterfacesDom {
  CssKeyframeRuleImpl.internal_() : super.internal_();
  get runtimeType => CssKeyframeRule;
  toString() => super.toString();
}
@patch class CssKeyframesRule {
  static Type get instanceRuntimeType => CssKeyframesRuleImpl;

}
class CssKeyframesRuleImpl extends CssKeyframesRule implements js_library.JSObjectInterfacesDom {
  CssKeyframesRuleImpl.internal_() : super.internal_();
  get runtimeType => CssKeyframesRule;
  toString() => super.toString();
}
@patch class CssMediaRule {
  static Type get instanceRuntimeType => CssMediaRuleImpl;

}
class CssMediaRuleImpl extends CssMediaRule implements js_library.JSObjectInterfacesDom {
  CssMediaRuleImpl.internal_() : super.internal_();
  get runtimeType => CssMediaRule;
  toString() => super.toString();
}
@patch class CssNamespaceRule {
  static Type get instanceRuntimeType => CssNamespaceRuleImpl;

}
class CssNamespaceRuleImpl extends CssNamespaceRule implements js_library.JSObjectInterfacesDom {
  CssNamespaceRuleImpl.internal_() : super.internal_();
  get runtimeType => CssNamespaceRule;
  toString() => super.toString();
}
@patch class CssPageRule {
  static Type get instanceRuntimeType => CssPageRuleImpl;

}
class CssPageRuleImpl extends CssPageRule implements js_library.JSObjectInterfacesDom {
  CssPageRuleImpl.internal_() : super.internal_();
  get runtimeType => CssPageRule;
  toString() => super.toString();
}
@patch class CssRule {
  static Type get instanceRuntimeType => CssRuleImpl;

}
class CssRuleImpl extends CssRule implements js_library.JSObjectInterfacesDom {
  CssRuleImpl.internal_() : super.internal_();
  get runtimeType => CssRule;
  toString() => super.toString();
}
@patch class CssStyleDeclaration {
  static Type get instanceRuntimeType => CssStyleDeclarationImpl;

}
class CssStyleDeclarationImpl extends CssStyleDeclaration implements js_library.JSObjectInterfacesDom {
  CssStyleDeclarationImpl.internal_() : super.internal_();
  get runtimeType => CssStyleDeclaration;
  toString() => super.toString();
}
@patch class CssStyleRule {
  static Type get instanceRuntimeType => CssStyleRuleImpl;

}
class CssStyleRuleImpl extends CssStyleRule implements js_library.JSObjectInterfacesDom {
  CssStyleRuleImpl.internal_() : super.internal_();
  get runtimeType => CssStyleRule;
  toString() => super.toString();
}
@patch class CssStyleSheet {
  static Type get instanceRuntimeType => CssStyleSheetImpl;

}
class CssStyleSheetImpl extends CssStyleSheet implements js_library.JSObjectInterfacesDom {
  CssStyleSheetImpl.internal_() : super.internal_();
  get runtimeType => CssStyleSheet;
  toString() => super.toString();
}
@patch class CssSupportsRule {
  static Type get instanceRuntimeType => CssSupportsRuleImpl;

}
class CssSupportsRuleImpl extends CssSupportsRule implements js_library.JSObjectInterfacesDom {
  CssSupportsRuleImpl.internal_() : super.internal_();
  get runtimeType => CssSupportsRule;
  toString() => super.toString();
}
@patch class CssViewportRule {
  static Type get instanceRuntimeType => CssViewportRuleImpl;

}
class CssViewportRuleImpl extends CssViewportRule implements js_library.JSObjectInterfacesDom {
  CssViewportRuleImpl.internal_() : super.internal_();
  get runtimeType => CssViewportRule;
  toString() => super.toString();
}
@patch class CustomEvent {
  static Type get instanceRuntimeType => CustomEventImpl;

}
class CustomEventImpl extends CustomEvent implements js_library.JSObjectInterfacesDom {
  CustomEventImpl.internal_() : super.internal_();
  get runtimeType => CustomEvent;
  toString() => super.toString();
}
@patch class DListElement {
  static Type get instanceRuntimeType => DListElementImpl;

}
class DListElementImpl extends DListElement implements js_library.JSObjectInterfacesDom {
  DListElementImpl.internal_() : super.internal_();
  get runtimeType => DListElement;
  toString() => super.toString();
}
@patch class DataListElement {
  static Type get instanceRuntimeType => DataListElementImpl;

}
class DataListElementImpl extends DataListElement implements js_library.JSObjectInterfacesDom {
  DataListElementImpl.internal_() : super.internal_();
  get runtimeType => DataListElement;
  toString() => super.toString();
}
@patch class DataTransfer {
  static Type get instanceRuntimeType => DataTransferImpl;

}
class DataTransferImpl extends DataTransfer implements js_library.JSObjectInterfacesDom {
  DataTransferImpl.internal_() : super.internal_();
  get runtimeType => DataTransfer;
  toString() => super.toString();
}
@patch class DataTransferItem {
  static Type get instanceRuntimeType => DataTransferItemImpl;

}
class DataTransferItemImpl extends DataTransferItem implements js_library.JSObjectInterfacesDom {
  DataTransferItemImpl.internal_() : super.internal_();
  get runtimeType => DataTransferItem;
  toString() => super.toString();
}
@patch class DataTransferItemList {
  static Type get instanceRuntimeType => DataTransferItemListImpl;

}
class DataTransferItemListImpl extends DataTransferItemList implements js_library.JSObjectInterfacesDom {
  DataTransferItemListImpl.internal_() : super.internal_();
  get runtimeType => DataTransferItemList;
  toString() => super.toString();
}
@patch class DedicatedWorkerGlobalScope {
  static Type get instanceRuntimeType => DedicatedWorkerGlobalScopeImpl;

}
class DedicatedWorkerGlobalScopeImpl extends DedicatedWorkerGlobalScope implements js_library.JSObjectInterfacesDom {
  DedicatedWorkerGlobalScopeImpl.internal_() : super.internal_();
  get runtimeType => DedicatedWorkerGlobalScope;
  toString() => super.toString();
}
@patch class DeprecatedStorageInfo {
  static Type get instanceRuntimeType => DeprecatedStorageInfoImpl;

}
class DeprecatedStorageInfoImpl extends DeprecatedStorageInfo implements js_library.JSObjectInterfacesDom {
  DeprecatedStorageInfoImpl.internal_() : super.internal_();
  get runtimeType => DeprecatedStorageInfo;
  toString() => super.toString();
}
@patch class DeprecatedStorageQuota {
  static Type get instanceRuntimeType => DeprecatedStorageQuotaImpl;

}
class DeprecatedStorageQuotaImpl extends DeprecatedStorageQuota implements js_library.JSObjectInterfacesDom {
  DeprecatedStorageQuotaImpl.internal_() : super.internal_();
  get runtimeType => DeprecatedStorageQuota;
  toString() => super.toString();
}
@patch class DetailsElement {
  static Type get instanceRuntimeType => DetailsElementImpl;

}
class DetailsElementImpl extends DetailsElement implements js_library.JSObjectInterfacesDom {
  DetailsElementImpl.internal_() : super.internal_();
  get runtimeType => DetailsElement;
  toString() => super.toString();
}
@patch class DeviceAcceleration {
  static Type get instanceRuntimeType => DeviceAccelerationImpl;

}
class DeviceAccelerationImpl extends DeviceAcceleration implements js_library.JSObjectInterfacesDom {
  DeviceAccelerationImpl.internal_() : super.internal_();
  get runtimeType => DeviceAcceleration;
  toString() => super.toString();
}
@patch class DeviceLightEvent {
  static Type get instanceRuntimeType => DeviceLightEventImpl;

}
class DeviceLightEventImpl extends DeviceLightEvent implements js_library.JSObjectInterfacesDom {
  DeviceLightEventImpl.internal_() : super.internal_();
  get runtimeType => DeviceLightEvent;
  toString() => super.toString();
}
@patch class DeviceMotionEvent {
  static Type get instanceRuntimeType => DeviceMotionEventImpl;

}
class DeviceMotionEventImpl extends DeviceMotionEvent implements js_library.JSObjectInterfacesDom {
  DeviceMotionEventImpl.internal_() : super.internal_();
  get runtimeType => DeviceMotionEvent;
  toString() => super.toString();
}
@patch class DeviceOrientationEvent {
  static Type get instanceRuntimeType => DeviceOrientationEventImpl;

}
class DeviceOrientationEventImpl extends DeviceOrientationEvent implements js_library.JSObjectInterfacesDom {
  DeviceOrientationEventImpl.internal_() : super.internal_();
  get runtimeType => DeviceOrientationEvent;
  toString() => super.toString();
}
@patch class DeviceRotationRate {
  static Type get instanceRuntimeType => DeviceRotationRateImpl;

}
class DeviceRotationRateImpl extends DeviceRotationRate implements js_library.JSObjectInterfacesDom {
  DeviceRotationRateImpl.internal_() : super.internal_();
  get runtimeType => DeviceRotationRate;
  toString() => super.toString();
}
@patch class DialogElement {
  static Type get instanceRuntimeType => DialogElementImpl;

}
class DialogElementImpl extends DialogElement implements js_library.JSObjectInterfacesDom {
  DialogElementImpl.internal_() : super.internal_();
  get runtimeType => DialogElement;
  toString() => super.toString();
}
@patch class DirectoryEntry {
  static Type get instanceRuntimeType => DirectoryEntryImpl;

}
class DirectoryEntryImpl extends DirectoryEntry implements js_library.JSObjectInterfacesDom {
  DirectoryEntryImpl.internal_() : super.internal_();
  get runtimeType => DirectoryEntry;
  toString() => super.toString();
}
@patch class DirectoryReader {
  static Type get instanceRuntimeType => DirectoryReaderImpl;

}
class DirectoryReaderImpl extends DirectoryReader implements js_library.JSObjectInterfacesDom {
  DirectoryReaderImpl.internal_() : super.internal_();
  get runtimeType => DirectoryReader;
  toString() => super.toString();
}
@patch class DivElement {
  static Type get instanceRuntimeType => DivElementImpl;

}
class DivElementImpl extends DivElement implements js_library.JSObjectInterfacesDom {
  DivElementImpl.internal_() : super.internal_();
  get runtimeType => DivElement;
  toString() => super.toString();
}
@patch class Document {
  static Type get instanceRuntimeType => DocumentImpl;

}
class DocumentImpl extends Document implements js_library.JSObjectInterfacesDom {
  DocumentImpl.internal_() : super.internal_();
  get runtimeType => Document;
  toString() => super.toString();
}
@patch class DocumentFragment {
  static Type get instanceRuntimeType => DocumentFragmentImpl;

}
class DocumentFragmentImpl extends DocumentFragment implements js_library.JSObjectInterfacesDom {
  DocumentFragmentImpl.internal_() : super.internal_();
  get runtimeType => DocumentFragment;
  toString() => super.toString();
}
@patch class DomError {
  static Type get instanceRuntimeType => DomErrorImpl;

}
class DomErrorImpl extends DomError implements js_library.JSObjectInterfacesDom {
  DomErrorImpl.internal_() : super.internal_();
  get runtimeType => DomError;
  toString() => super.toString();
}
@patch class DomException {
  static Type get instanceRuntimeType => DomExceptionImpl;

}
class DomExceptionImpl extends DomException implements js_library.JSObjectInterfacesDom {
  DomExceptionImpl.internal_() : super.internal_();
  get runtimeType => DomException;
  toString() => super.toString();
}
@patch class DomImplementation {
  static Type get instanceRuntimeType => DomImplementationImpl;

}
class DomImplementationImpl extends DomImplementation implements js_library.JSObjectInterfacesDom {
  DomImplementationImpl.internal_() : super.internal_();
  get runtimeType => DomImplementation;
  toString() => super.toString();
}
@patch class DomIterator {
  static Type get instanceRuntimeType => DomIteratorImpl;

}
class DomIteratorImpl extends DomIterator implements js_library.JSObjectInterfacesDom {
  DomIteratorImpl.internal_() : super.internal_();
  get runtimeType => DomIterator;
  toString() => super.toString();
}
@patch class DomMatrix {
  static Type get instanceRuntimeType => DomMatrixImpl;

}
class DomMatrixImpl extends DomMatrix implements js_library.JSObjectInterfacesDom {
  DomMatrixImpl.internal_() : super.internal_();
  get runtimeType => DomMatrix;
  toString() => super.toString();
}
@patch class DomMatrixReadOnly {
  static Type get instanceRuntimeType => DomMatrixReadOnlyImpl;

}
class DomMatrixReadOnlyImpl extends DomMatrixReadOnly implements js_library.JSObjectInterfacesDom {
  DomMatrixReadOnlyImpl.internal_() : super.internal_();
  get runtimeType => DomMatrixReadOnly;
  toString() => super.toString();
}
@patch class DomParser {
  static Type get instanceRuntimeType => DomParserImpl;

}
class DomParserImpl extends DomParser implements js_library.JSObjectInterfacesDom {
  DomParserImpl.internal_() : super.internal_();
  get runtimeType => DomParser;
  toString() => super.toString();
}
@patch class DomPoint {
  static Type get instanceRuntimeType => DomPointImpl;

}
class DomPointImpl extends DomPoint implements js_library.JSObjectInterfacesDom {
  DomPointImpl.internal_() : super.internal_();
  get runtimeType => DomPoint;
  toString() => super.toString();
}
@patch class DomPointReadOnly {
  static Type get instanceRuntimeType => DomPointReadOnlyImpl;

}
class DomPointReadOnlyImpl extends DomPointReadOnly implements js_library.JSObjectInterfacesDom {
  DomPointReadOnlyImpl.internal_() : super.internal_();
  get runtimeType => DomPointReadOnly;
  toString() => super.toString();
}
@patch class DomRectReadOnly {
  static Type get instanceRuntimeType => DomRectReadOnlyImpl;

}
class DomRectReadOnlyImpl extends DomRectReadOnly implements js_library.JSObjectInterfacesDom {
  DomRectReadOnlyImpl.internal_() : super.internal_();
  get runtimeType => DomRectReadOnly;
  toString() => super.toString();
}
@patch class DomStringList {
  static Type get instanceRuntimeType => DomStringListImpl;

}
class DomStringListImpl extends DomStringList implements js_library.JSObjectInterfacesDom {
  DomStringListImpl.internal_() : super.internal_();
  get runtimeType => DomStringList;
  toString() => super.toString();
}
@patch class DomStringMap {
  static Type get instanceRuntimeType => DomStringMapImpl;

}
class DomStringMapImpl extends DomStringMap implements js_library.JSObjectInterfacesDom {
  DomStringMapImpl.internal_() : super.internal_();
  get runtimeType => DomStringMap;
  toString() => super.toString();
}
@patch class DomTokenList {
  static Type get instanceRuntimeType => DomTokenListImpl;

}
class DomTokenListImpl extends DomTokenList implements js_library.JSObjectInterfacesDom {
  DomTokenListImpl.internal_() : super.internal_();
  get runtimeType => DomTokenList;
  toString() => super.toString();
}
@patch class EffectModel {
  static Type get instanceRuntimeType => EffectModelImpl;

}
class EffectModelImpl extends EffectModel implements js_library.JSObjectInterfacesDom {
  EffectModelImpl.internal_() : super.internal_();
  get runtimeType => EffectModel;
  toString() => super.toString();
}
@patch class Element {
  static Type get instanceRuntimeType => ElementImpl;

}
class ElementImpl extends Element implements js_library.JSObjectInterfacesDom {
  ElementImpl.internal_() : super.internal_();
  get runtimeType => Element;
  toString() => super.toString();
}
@patch class EmbedElement {
  static Type get instanceRuntimeType => EmbedElementImpl;

}
class EmbedElementImpl extends EmbedElement implements js_library.JSObjectInterfacesDom {
  EmbedElementImpl.internal_() : super.internal_();
  get runtimeType => EmbedElement;
  toString() => super.toString();
}
@patch class Entry {
  static Type get instanceRuntimeType => EntryImpl;

}
class EntryImpl extends Entry implements js_library.JSObjectInterfacesDom {
  EntryImpl.internal_() : super.internal_();
  get runtimeType => Entry;
  toString() => super.toString();
}
@patch class ErrorEvent {
  static Type get instanceRuntimeType => ErrorEventImpl;

}
class ErrorEventImpl extends ErrorEvent implements js_library.JSObjectInterfacesDom {
  ErrorEventImpl.internal_() : super.internal_();
  get runtimeType => ErrorEvent;
  toString() => super.toString();
}
@patch class Event {
  static Type get instanceRuntimeType => EventImpl;

}
class EventImpl extends Event implements js_library.JSObjectInterfacesDom {
  EventImpl.internal_() : super.internal_();
  get runtimeType => Event;
  toString() => super.toString();
}
@patch class EventSource {
  static Type get instanceRuntimeType => EventSourceImpl;

}
class EventSourceImpl extends EventSource implements js_library.JSObjectInterfacesDom {
  EventSourceImpl.internal_() : super.internal_();
  get runtimeType => EventSource;
  toString() => super.toString();
}
@patch class EventTarget {
  static Type get instanceRuntimeType => EventTargetImpl;

}
class EventTargetImpl extends EventTarget implements js_library.JSObjectInterfacesDom {
  EventTargetImpl.internal_() : super.internal_();
  get runtimeType => EventTarget;
  toString() => super.toString();
}
@patch class ExtendableEvent {
  static Type get instanceRuntimeType => ExtendableEventImpl;

}
class ExtendableEventImpl extends ExtendableEvent implements js_library.JSObjectInterfacesDom {
  ExtendableEventImpl.internal_() : super.internal_();
  get runtimeType => ExtendableEvent;
  toString() => super.toString();
}
@patch class ExtendableMessageEvent {
  static Type get instanceRuntimeType => ExtendableMessageEventImpl;

}
class ExtendableMessageEventImpl extends ExtendableMessageEvent implements js_library.JSObjectInterfacesDom {
  ExtendableMessageEventImpl.internal_() : super.internal_();
  get runtimeType => ExtendableMessageEvent;
  toString() => super.toString();
}
@patch class FederatedCredential {
  static Type get instanceRuntimeType => FederatedCredentialImpl;

}
class FederatedCredentialImpl extends FederatedCredential implements js_library.JSObjectInterfacesDom {
  FederatedCredentialImpl.internal_() : super.internal_();
  get runtimeType => FederatedCredential;
  toString() => super.toString();
}
@patch class FetchEvent {
  static Type get instanceRuntimeType => FetchEventImpl;

}
class FetchEventImpl extends FetchEvent implements js_library.JSObjectInterfacesDom {
  FetchEventImpl.internal_() : super.internal_();
  get runtimeType => FetchEvent;
  toString() => super.toString();
}
@patch class FieldSetElement {
  static Type get instanceRuntimeType => FieldSetElementImpl;

}
class FieldSetElementImpl extends FieldSetElement implements js_library.JSObjectInterfacesDom {
  FieldSetElementImpl.internal_() : super.internal_();
  get runtimeType => FieldSetElement;
  toString() => super.toString();
}
@patch class File {
  static Type get instanceRuntimeType => FileImpl;

}
class FileImpl extends File implements js_library.JSObjectInterfacesDom {
  FileImpl.internal_() : super.internal_();
  get runtimeType => File;
  toString() => super.toString();
}
@patch class FileEntry {
  static Type get instanceRuntimeType => FileEntryImpl;

}
class FileEntryImpl extends FileEntry implements js_library.JSObjectInterfacesDom {
  FileEntryImpl.internal_() : super.internal_();
  get runtimeType => FileEntry;
  toString() => super.toString();
}
@patch class FileError {
  static Type get instanceRuntimeType => FileErrorImpl;

}
class FileErrorImpl extends FileError implements js_library.JSObjectInterfacesDom {
  FileErrorImpl.internal_() : super.internal_();
  get runtimeType => FileError;
  toString() => super.toString();
}
@patch class FileList {
  static Type get instanceRuntimeType => FileListImpl;

}
class FileListImpl extends FileList implements js_library.JSObjectInterfacesDom {
  FileListImpl.internal_() : super.internal_();
  get runtimeType => FileList;
  toString() => super.toString();
}
@patch class FileReader {
  static Type get instanceRuntimeType => FileReaderImpl;

}
class FileReaderImpl extends FileReader implements js_library.JSObjectInterfacesDom {
  FileReaderImpl.internal_() : super.internal_();
  get runtimeType => FileReader;
  toString() => super.toString();
}
@patch class FileStream {
  static Type get instanceRuntimeType => FileStreamImpl;

}
class FileStreamImpl extends FileStream implements js_library.JSObjectInterfacesDom {
  FileStreamImpl.internal_() : super.internal_();
  get runtimeType => FileStream;
  toString() => super.toString();
}
@patch class FileSystem {
  static Type get instanceRuntimeType => FileSystemImpl;

}
class FileSystemImpl extends FileSystem implements js_library.JSObjectInterfacesDom {
  FileSystemImpl.internal_() : super.internal_();
  get runtimeType => FileSystem;
  toString() => super.toString();
}
@patch class FileWriter {
  static Type get instanceRuntimeType => FileWriterImpl;

}
class FileWriterImpl extends FileWriter implements js_library.JSObjectInterfacesDom {
  FileWriterImpl.internal_() : super.internal_();
  get runtimeType => FileWriter;
  toString() => super.toString();
}
@patch class FocusEvent {
  static Type get instanceRuntimeType => FocusEventImpl;

}
class FocusEventImpl extends FocusEvent implements js_library.JSObjectInterfacesDom {
  FocusEventImpl.internal_() : super.internal_();
  get runtimeType => FocusEvent;
  toString() => super.toString();
}
@patch class FontFace {
  static Type get instanceRuntimeType => FontFaceImpl;

}
class FontFaceImpl extends FontFace implements js_library.JSObjectInterfacesDom {
  FontFaceImpl.internal_() : super.internal_();
  get runtimeType => FontFace;
  toString() => super.toString();
}
@patch class FontFaceSet {
  static Type get instanceRuntimeType => FontFaceSetImpl;

}
class FontFaceSetImpl extends FontFaceSet implements js_library.JSObjectInterfacesDom {
  FontFaceSetImpl.internal_() : super.internal_();
  get runtimeType => FontFaceSet;
  toString() => super.toString();
}
@patch class FontFaceSetLoadEvent {
  static Type get instanceRuntimeType => FontFaceSetLoadEventImpl;

}
class FontFaceSetLoadEventImpl extends FontFaceSetLoadEvent implements js_library.JSObjectInterfacesDom {
  FontFaceSetLoadEventImpl.internal_() : super.internal_();
  get runtimeType => FontFaceSetLoadEvent;
  toString() => super.toString();
}
@patch class FormData {
  static Type get instanceRuntimeType => FormDataImpl;

}
class FormDataImpl extends FormData implements js_library.JSObjectInterfacesDom {
  FormDataImpl.internal_() : super.internal_();
  get runtimeType => FormData;
  toString() => super.toString();
}
@patch class FormElement {
  static Type get instanceRuntimeType => FormElementImpl;

}
class FormElementImpl extends FormElement implements js_library.JSObjectInterfacesDom {
  FormElementImpl.internal_() : super.internal_();
  get runtimeType => FormElement;
  toString() => super.toString();
}
@patch class Gamepad {
  static Type get instanceRuntimeType => GamepadImpl;

}
class GamepadImpl extends Gamepad implements js_library.JSObjectInterfacesDom {
  GamepadImpl.internal_() : super.internal_();
  get runtimeType => Gamepad;
  toString() => super.toString();
}
@patch class GamepadButton {
  static Type get instanceRuntimeType => GamepadButtonImpl;

}
class GamepadButtonImpl extends GamepadButton implements js_library.JSObjectInterfacesDom {
  GamepadButtonImpl.internal_() : super.internal_();
  get runtimeType => GamepadButton;
  toString() => super.toString();
}
@patch class GamepadEvent {
  static Type get instanceRuntimeType => GamepadEventImpl;

}
class GamepadEventImpl extends GamepadEvent implements js_library.JSObjectInterfacesDom {
  GamepadEventImpl.internal_() : super.internal_();
  get runtimeType => GamepadEvent;
  toString() => super.toString();
}
@patch class Geofencing {
  static Type get instanceRuntimeType => GeofencingImpl;

}
class GeofencingImpl extends Geofencing implements js_library.JSObjectInterfacesDom {
  GeofencingImpl.internal_() : super.internal_();
  get runtimeType => Geofencing;
  toString() => super.toString();
}
@patch class GeofencingEvent {
  static Type get instanceRuntimeType => GeofencingEventImpl;

}
class GeofencingEventImpl extends GeofencingEvent implements js_library.JSObjectInterfacesDom {
  GeofencingEventImpl.internal_() : super.internal_();
  get runtimeType => GeofencingEvent;
  toString() => super.toString();
}
@patch class GeofencingRegion {
  static Type get instanceRuntimeType => GeofencingRegionImpl;

}
class GeofencingRegionImpl extends GeofencingRegion implements js_library.JSObjectInterfacesDom {
  GeofencingRegionImpl.internal_() : super.internal_();
  get runtimeType => GeofencingRegion;
  toString() => super.toString();
}
@patch class Geolocation {
  static Type get instanceRuntimeType => GeolocationImpl;

}
class GeolocationImpl extends Geolocation implements js_library.JSObjectInterfacesDom {
  GeolocationImpl.internal_() : super.internal_();
  get runtimeType => Geolocation;
  toString() => super.toString();
}
@patch class Geoposition {
  static Type get instanceRuntimeType => GeopositionImpl;

}
class GeopositionImpl extends Geoposition implements js_library.JSObjectInterfacesDom {
  GeopositionImpl.internal_() : super.internal_();
  get runtimeType => Geoposition;
  toString() => super.toString();
}
@patch class GlobalEventHandlers {
  static Type get instanceRuntimeType => GlobalEventHandlersImpl;

}
class GlobalEventHandlersImpl extends GlobalEventHandlers implements js_library.JSObjectInterfacesDom {
  GlobalEventHandlersImpl.internal_() : super.internal_();
  get runtimeType => GlobalEventHandlers;
  toString() => super.toString();
}
@patch class HRElement {
  static Type get instanceRuntimeType => HRElementImpl;

}
class HRElementImpl extends HRElement implements js_library.JSObjectInterfacesDom {
  HRElementImpl.internal_() : super.internal_();
  get runtimeType => HRElement;
  toString() => super.toString();
}
@patch class HashChangeEvent {
  static Type get instanceRuntimeType => HashChangeEventImpl;

}
class HashChangeEventImpl extends HashChangeEvent implements js_library.JSObjectInterfacesDom {
  HashChangeEventImpl.internal_() : super.internal_();
  get runtimeType => HashChangeEvent;
  toString() => super.toString();
}
@patch class HeadElement {
  static Type get instanceRuntimeType => HeadElementImpl;

}
class HeadElementImpl extends HeadElement implements js_library.JSObjectInterfacesDom {
  HeadElementImpl.internal_() : super.internal_();
  get runtimeType => HeadElement;
  toString() => super.toString();
}
@patch class Headers {
  static Type get instanceRuntimeType => HeadersImpl;

}
class HeadersImpl extends Headers implements js_library.JSObjectInterfacesDom {
  HeadersImpl.internal_() : super.internal_();
  get runtimeType => Headers;
  toString() => super.toString();
}
@patch class HeadingElement {
  static Type get instanceRuntimeType => HeadingElementImpl;

}
class HeadingElementImpl extends HeadingElement implements js_library.JSObjectInterfacesDom {
  HeadingElementImpl.internal_() : super.internal_();
  get runtimeType => HeadingElement;
  toString() => super.toString();
}
@patch class History {
  static Type get instanceRuntimeType => HistoryImpl;

}
class HistoryImpl extends History implements js_library.JSObjectInterfacesDom {
  HistoryImpl.internal_() : super.internal_();
  get runtimeType => History;
  toString() => super.toString();
}
@patch class HmdvrDevice {
  static Type get instanceRuntimeType => HmdvrDeviceImpl;

}
class HmdvrDeviceImpl extends HmdvrDevice implements js_library.JSObjectInterfacesDom {
  HmdvrDeviceImpl.internal_() : super.internal_();
  get runtimeType => HmdvrDevice;
  toString() => super.toString();
}
@patch class HtmlCollection {
  static Type get instanceRuntimeType => HtmlCollectionImpl;

}
class HtmlCollectionImpl extends HtmlCollection implements js_library.JSObjectInterfacesDom {
  HtmlCollectionImpl.internal_() : super.internal_();
  get runtimeType => HtmlCollection;
  toString() => super.toString();
}
@patch class HtmlDocument {
  static Type get instanceRuntimeType => HtmlDocumentImpl;

}
class HtmlDocumentImpl extends HtmlDocument implements js_library.JSObjectInterfacesDom {
  HtmlDocumentImpl.internal_() : super.internal_();
  get runtimeType => HtmlDocument;
  toString() => super.toString();
}
@patch class HtmlElement {
  static Type get instanceRuntimeType => HtmlElementImpl;

}
class HtmlElementImpl extends HtmlElement implements js_library.JSObjectInterfacesDom {
  HtmlElementImpl.internal_() : super.internal_();
  get runtimeType => HtmlElement;
  toString() => super.toString();
}
@patch class HtmlFormControlsCollection {
  static Type get instanceRuntimeType => HtmlFormControlsCollectionImpl;

}
class HtmlFormControlsCollectionImpl extends HtmlFormControlsCollection implements js_library.JSObjectInterfacesDom {
  HtmlFormControlsCollectionImpl.internal_() : super.internal_();
  get runtimeType => HtmlFormControlsCollection;
  toString() => super.toString();
}
@patch class HtmlHtmlElement {
  static Type get instanceRuntimeType => HtmlHtmlElementImpl;

}
class HtmlHtmlElementImpl extends HtmlHtmlElement implements js_library.JSObjectInterfacesDom {
  HtmlHtmlElementImpl.internal_() : super.internal_();
  get runtimeType => HtmlHtmlElement;
  toString() => super.toString();
}
@patch class HtmlOptionsCollection {
  static Type get instanceRuntimeType => HtmlOptionsCollectionImpl;

}
class HtmlOptionsCollectionImpl extends HtmlOptionsCollection implements js_library.JSObjectInterfacesDom {
  HtmlOptionsCollectionImpl.internal_() : super.internal_();
  get runtimeType => HtmlOptionsCollection;
  toString() => super.toString();
}
@patch class HttpRequest {
  static Type get instanceRuntimeType => HttpRequestImpl;

}
class HttpRequestImpl extends HttpRequest implements js_library.JSObjectInterfacesDom {
  HttpRequestImpl.internal_() : super.internal_();
  get runtimeType => HttpRequest;
  toString() => super.toString();
}
@patch class HttpRequestEventTarget {
  static Type get instanceRuntimeType => HttpRequestEventTargetImpl;

}
class HttpRequestEventTargetImpl extends HttpRequestEventTarget implements js_library.JSObjectInterfacesDom {
  HttpRequestEventTargetImpl.internal_() : super.internal_();
  get runtimeType => HttpRequestEventTarget;
  toString() => super.toString();
}
@patch class HttpRequestUpload {
  static Type get instanceRuntimeType => HttpRequestUploadImpl;

}
class HttpRequestUploadImpl extends HttpRequestUpload implements js_library.JSObjectInterfacesDom {
  HttpRequestUploadImpl.internal_() : super.internal_();
  get runtimeType => HttpRequestUpload;
  toString() => super.toString();
}
@patch class IFrameElement {
  static Type get instanceRuntimeType => IFrameElementImpl;

}
class IFrameElementImpl extends IFrameElement implements js_library.JSObjectInterfacesDom {
  IFrameElementImpl.internal_() : super.internal_();
  get runtimeType => IFrameElement;
  toString() => super.toString();
}
@patch class IdleDeadline {
  static Type get instanceRuntimeType => IdleDeadlineImpl;

}
class IdleDeadlineImpl extends IdleDeadline implements js_library.JSObjectInterfacesDom {
  IdleDeadlineImpl.internal_() : super.internal_();
  get runtimeType => IdleDeadline;
  toString() => super.toString();
}
@patch class ImageBitmap {
  static Type get instanceRuntimeType => ImageBitmapImpl;

}
class ImageBitmapImpl extends ImageBitmap implements js_library.JSObjectInterfacesDom {
  ImageBitmapImpl.internal_() : super.internal_();
  get runtimeType => ImageBitmap;
  toString() => super.toString();
}
@patch class ImageBitmapRenderingContext {
  static Type get instanceRuntimeType => ImageBitmapRenderingContextImpl;

}
class ImageBitmapRenderingContextImpl extends ImageBitmapRenderingContext implements js_library.JSObjectInterfacesDom {
  ImageBitmapRenderingContextImpl.internal_() : super.internal_();
  get runtimeType => ImageBitmapRenderingContext;
  toString() => super.toString();
}
@patch class ImageData {
  static Type get instanceRuntimeType => ImageDataImpl;

}
class ImageDataImpl extends ImageData implements js_library.JSObjectInterfacesDom {
  ImageDataImpl.internal_() : super.internal_();
  get runtimeType => ImageData;
  toString() => super.toString();
}
@patch class ImageElement {
  static Type get instanceRuntimeType => ImageElementImpl;

}
class ImageElementImpl extends ImageElement implements js_library.JSObjectInterfacesDom {
  ImageElementImpl.internal_() : super.internal_();
  get runtimeType => ImageElement;
  toString() => super.toString();
}
@patch class InjectedScriptHost {
  static Type get instanceRuntimeType => InjectedScriptHostImpl;

}
class InjectedScriptHostImpl extends InjectedScriptHost implements js_library.JSObjectInterfacesDom {
  InjectedScriptHostImpl.internal_() : super.internal_();
  get runtimeType => InjectedScriptHost;
  toString() => super.toString();
}
@patch class InputDeviceCapabilities {
  static Type get instanceRuntimeType => InputDeviceCapabilitiesImpl;

}
class InputDeviceCapabilitiesImpl extends InputDeviceCapabilities implements js_library.JSObjectInterfacesDom {
  InputDeviceCapabilitiesImpl.internal_() : super.internal_();
  get runtimeType => InputDeviceCapabilities;
  toString() => super.toString();
}
@patch class InputElement {
  static Type get instanceRuntimeType => InputElementImpl;

}
class InputElementImpl extends InputElement implements js_library.JSObjectInterfacesDom {
  InputElementImpl.internal_() : super.internal_();
  get runtimeType => InputElement;
  toString() => super.toString();
}
@patch class InstallEvent {
  static Type get instanceRuntimeType => InstallEventImpl;

}
class InstallEventImpl extends InstallEvent implements js_library.JSObjectInterfacesDom {
  InstallEventImpl.internal_() : super.internal_();
  get runtimeType => InstallEvent;
  toString() => super.toString();
}
@patch class IntersectionObserver {
  static Type get instanceRuntimeType => IntersectionObserverImpl;

}
class IntersectionObserverImpl extends IntersectionObserver implements js_library.JSObjectInterfacesDom {
  IntersectionObserverImpl.internal_() : super.internal_();
  get runtimeType => IntersectionObserver;
  toString() => super.toString();
}
@patch class IntersectionObserverEntry {
  static Type get instanceRuntimeType => IntersectionObserverEntryImpl;

}
class IntersectionObserverEntryImpl extends IntersectionObserverEntry implements js_library.JSObjectInterfacesDom {
  IntersectionObserverEntryImpl.internal_() : super.internal_();
  get runtimeType => IntersectionObserverEntry;
  toString() => super.toString();
}
@patch class KeyboardEvent {
  static Type get instanceRuntimeType => KeyboardEventImpl;

}
class KeyboardEventImpl extends KeyboardEvent implements js_library.JSObjectInterfacesDom {
  KeyboardEventImpl.internal_() : super.internal_();
  get runtimeType => KeyboardEvent;
  toString() => super.toString();
}
@patch class KeyframeEffect {
  static Type get instanceRuntimeType => KeyframeEffectImpl;

}
class KeyframeEffectImpl extends KeyframeEffect implements js_library.JSObjectInterfacesDom {
  KeyframeEffectImpl.internal_() : super.internal_();
  get runtimeType => KeyframeEffect;
  toString() => super.toString();
}
@patch class KeygenElement {
  static Type get instanceRuntimeType => KeygenElementImpl;

}
class KeygenElementImpl extends KeygenElement implements js_library.JSObjectInterfacesDom {
  KeygenElementImpl.internal_() : super.internal_();
  get runtimeType => KeygenElement;
  toString() => super.toString();
}
@patch class KeywordValue {
  static Type get instanceRuntimeType => KeywordValueImpl;

}
class KeywordValueImpl extends KeywordValue implements js_library.JSObjectInterfacesDom {
  KeywordValueImpl.internal_() : super.internal_();
  get runtimeType => KeywordValue;
  toString() => super.toString();
}
@patch class LIElement {
  static Type get instanceRuntimeType => LIElementImpl;

}
class LIElementImpl extends LIElement implements js_library.JSObjectInterfacesDom {
  LIElementImpl.internal_() : super.internal_();
  get runtimeType => LIElement;
  toString() => super.toString();
}
@patch class LabelElement {
  static Type get instanceRuntimeType => LabelElementImpl;

}
class LabelElementImpl extends LabelElement implements js_library.JSObjectInterfacesDom {
  LabelElementImpl.internal_() : super.internal_();
  get runtimeType => LabelElement;
  toString() => super.toString();
}
@patch class LegendElement {
  static Type get instanceRuntimeType => LegendElementImpl;

}
class LegendElementImpl extends LegendElement implements js_library.JSObjectInterfacesDom {
  LegendElementImpl.internal_() : super.internal_();
  get runtimeType => LegendElement;
  toString() => super.toString();
}
@patch class LengthValue {
  static Type get instanceRuntimeType => LengthValueImpl;

}
class LengthValueImpl extends LengthValue implements js_library.JSObjectInterfacesDom {
  LengthValueImpl.internal_() : super.internal_();
  get runtimeType => LengthValue;
  toString() => super.toString();
}
@patch class LinkElement {
  static Type get instanceRuntimeType => LinkElementImpl;

}
class LinkElementImpl extends LinkElement implements js_library.JSObjectInterfacesDom {
  LinkElementImpl.internal_() : super.internal_();
  get runtimeType => LinkElement;
  toString() => super.toString();
}
@patch class Location {
  static Type get instanceRuntimeType => LocationImpl;

}
class LocationImpl extends Location implements js_library.JSObjectInterfacesDom {
  LocationImpl.internal_() : super.internal_();
  get runtimeType => Location;
  toString() => super.toString();
}
@patch class MapElement {
  static Type get instanceRuntimeType => MapElementImpl;

}
class MapElementImpl extends MapElement implements js_library.JSObjectInterfacesDom {
  MapElementImpl.internal_() : super.internal_();
  get runtimeType => MapElement;
  toString() => super.toString();
}
@patch class Matrix {
  static Type get instanceRuntimeType => MatrixImpl;

}
class MatrixImpl extends Matrix implements js_library.JSObjectInterfacesDom {
  MatrixImpl.internal_() : super.internal_();
  get runtimeType => Matrix;
  toString() => super.toString();
}
@patch class MediaDeviceInfo {
  static Type get instanceRuntimeType => MediaDeviceInfoImpl;

}
class MediaDeviceInfoImpl extends MediaDeviceInfo implements js_library.JSObjectInterfacesDom {
  MediaDeviceInfoImpl.internal_() : super.internal_();
  get runtimeType => MediaDeviceInfo;
  toString() => super.toString();
}
@patch class MediaDevices {
  static Type get instanceRuntimeType => MediaDevicesImpl;

}
class MediaDevicesImpl extends MediaDevices implements js_library.JSObjectInterfacesDom {
  MediaDevicesImpl.internal_() : super.internal_();
  get runtimeType => MediaDevices;
  toString() => super.toString();
}
@patch class MediaElement {
  static Type get instanceRuntimeType => MediaElementImpl;

}
class MediaElementImpl extends MediaElement implements js_library.JSObjectInterfacesDom {
  MediaElementImpl.internal_() : super.internal_();
  get runtimeType => MediaElement;
  toString() => super.toString();
}
@patch class MediaEncryptedEvent {
  static Type get instanceRuntimeType => MediaEncryptedEventImpl;

}
class MediaEncryptedEventImpl extends MediaEncryptedEvent implements js_library.JSObjectInterfacesDom {
  MediaEncryptedEventImpl.internal_() : super.internal_();
  get runtimeType => MediaEncryptedEvent;
  toString() => super.toString();
}
@patch class MediaError {
  static Type get instanceRuntimeType => MediaErrorImpl;

}
class MediaErrorImpl extends MediaError implements js_library.JSObjectInterfacesDom {
  MediaErrorImpl.internal_() : super.internal_();
  get runtimeType => MediaError;
  toString() => super.toString();
}
@patch class MediaKeyMessageEvent {
  static Type get instanceRuntimeType => MediaKeyMessageEventImpl;

}
class MediaKeyMessageEventImpl extends MediaKeyMessageEvent implements js_library.JSObjectInterfacesDom {
  MediaKeyMessageEventImpl.internal_() : super.internal_();
  get runtimeType => MediaKeyMessageEvent;
  toString() => super.toString();
}
@patch class MediaKeySession {
  static Type get instanceRuntimeType => MediaKeySessionImpl;

}
class MediaKeySessionImpl extends MediaKeySession implements js_library.JSObjectInterfacesDom {
  MediaKeySessionImpl.internal_() : super.internal_();
  get runtimeType => MediaKeySession;
  toString() => super.toString();
}
@patch class MediaKeyStatusMap {
  static Type get instanceRuntimeType => MediaKeyStatusMapImpl;

}
class MediaKeyStatusMapImpl extends MediaKeyStatusMap implements js_library.JSObjectInterfacesDom {
  MediaKeyStatusMapImpl.internal_() : super.internal_();
  get runtimeType => MediaKeyStatusMap;
  toString() => super.toString();
}
@patch class MediaKeySystemAccess {
  static Type get instanceRuntimeType => MediaKeySystemAccessImpl;

}
class MediaKeySystemAccessImpl extends MediaKeySystemAccess implements js_library.JSObjectInterfacesDom {
  MediaKeySystemAccessImpl.internal_() : super.internal_();
  get runtimeType => MediaKeySystemAccess;
  toString() => super.toString();
}
@patch class MediaKeys {
  static Type get instanceRuntimeType => MediaKeysImpl;

}
class MediaKeysImpl extends MediaKeys implements js_library.JSObjectInterfacesDom {
  MediaKeysImpl.internal_() : super.internal_();
  get runtimeType => MediaKeys;
  toString() => super.toString();
}
@patch class MediaList {
  static Type get instanceRuntimeType => MediaListImpl;

}
class MediaListImpl extends MediaList implements js_library.JSObjectInterfacesDom {
  MediaListImpl.internal_() : super.internal_();
  get runtimeType => MediaList;
  toString() => super.toString();
}
@patch class MediaMetadata {
  static Type get instanceRuntimeType => MediaMetadataImpl;

}
class MediaMetadataImpl extends MediaMetadata implements js_library.JSObjectInterfacesDom {
  MediaMetadataImpl.internal_() : super.internal_();
  get runtimeType => MediaMetadata;
  toString() => super.toString();
}
@patch class MediaQueryList {
  static Type get instanceRuntimeType => MediaQueryListImpl;

}
class MediaQueryListImpl extends MediaQueryList implements js_library.JSObjectInterfacesDom {
  MediaQueryListImpl.internal_() : super.internal_();
  get runtimeType => MediaQueryList;
  toString() => super.toString();
}
@patch class MediaQueryListEvent {
  static Type get instanceRuntimeType => MediaQueryListEventImpl;

}
class MediaQueryListEventImpl extends MediaQueryListEvent implements js_library.JSObjectInterfacesDom {
  MediaQueryListEventImpl.internal_() : super.internal_();
  get runtimeType => MediaQueryListEvent;
  toString() => super.toString();
}
@patch class MediaRecorder {
  static Type get instanceRuntimeType => MediaRecorderImpl;

}
class MediaRecorderImpl extends MediaRecorder implements js_library.JSObjectInterfacesDom {
  MediaRecorderImpl.internal_() : super.internal_();
  get runtimeType => MediaRecorder;
  toString() => super.toString();
}
@patch class MediaSession {
  static Type get instanceRuntimeType => MediaSessionImpl;

}
class MediaSessionImpl extends MediaSession implements js_library.JSObjectInterfacesDom {
  MediaSessionImpl.internal_() : super.internal_();
  get runtimeType => MediaSession;
  toString() => super.toString();
}
@patch class MediaSource {
  static Type get instanceRuntimeType => MediaSourceImpl;

}
class MediaSourceImpl extends MediaSource implements js_library.JSObjectInterfacesDom {
  MediaSourceImpl.internal_() : super.internal_();
  get runtimeType => MediaSource;
  toString() => super.toString();
}
@patch class MediaStream {
  static Type get instanceRuntimeType => MediaStreamImpl;

}
class MediaStreamImpl extends MediaStream implements js_library.JSObjectInterfacesDom {
  MediaStreamImpl.internal_() : super.internal_();
  get runtimeType => MediaStream;
  toString() => super.toString();
}
@patch class MediaStreamEvent {
  static Type get instanceRuntimeType => MediaStreamEventImpl;

}
class MediaStreamEventImpl extends MediaStreamEvent implements js_library.JSObjectInterfacesDom {
  MediaStreamEventImpl.internal_() : super.internal_();
  get runtimeType => MediaStreamEvent;
  toString() => super.toString();
}
@patch class MediaStreamTrack {
  static Type get instanceRuntimeType => MediaStreamTrackImpl;

}
class MediaStreamTrackImpl extends MediaStreamTrack implements js_library.JSObjectInterfacesDom {
  MediaStreamTrackImpl.internal_() : super.internal_();
  get runtimeType => MediaStreamTrack;
  toString() => super.toString();
}
@patch class MediaStreamTrackEvent {
  static Type get instanceRuntimeType => MediaStreamTrackEventImpl;

}
class MediaStreamTrackEventImpl extends MediaStreamTrackEvent implements js_library.JSObjectInterfacesDom {
  MediaStreamTrackEventImpl.internal_() : super.internal_();
  get runtimeType => MediaStreamTrackEvent;
  toString() => super.toString();
}
@patch class MemoryInfo {
  static Type get instanceRuntimeType => MemoryInfoImpl;

}
class MemoryInfoImpl extends MemoryInfo implements js_library.JSObjectInterfacesDom {
  MemoryInfoImpl.internal_() : super.internal_();
  get runtimeType => MemoryInfo;
  toString() => super.toString();
}
@patch class MenuElement {
  static Type get instanceRuntimeType => MenuElementImpl;

}
class MenuElementImpl extends MenuElement implements js_library.JSObjectInterfacesDom {
  MenuElementImpl.internal_() : super.internal_();
  get runtimeType => MenuElement;
  toString() => super.toString();
}
@patch class MenuItemElement {
  static Type get instanceRuntimeType => MenuItemElementImpl;

}
class MenuItemElementImpl extends MenuItemElement implements js_library.JSObjectInterfacesDom {
  MenuItemElementImpl.internal_() : super.internal_();
  get runtimeType => MenuItemElement;
  toString() => super.toString();
}
@patch class MessageChannel {
  static Type get instanceRuntimeType => MessageChannelImpl;

}
class MessageChannelImpl extends MessageChannel implements js_library.JSObjectInterfacesDom {
  MessageChannelImpl.internal_() : super.internal_();
  get runtimeType => MessageChannel;
  toString() => super.toString();
}
@patch class MessageEvent {
  static Type get instanceRuntimeType => MessageEventImpl;

}
class MessageEventImpl extends MessageEvent implements js_library.JSObjectInterfacesDom {
  MessageEventImpl.internal_() : super.internal_();
  get runtimeType => MessageEvent;
  toString() => super.toString();
}
@patch class MessagePort {
  static Type get instanceRuntimeType => MessagePortImpl;

}
class MessagePortImpl extends MessagePort implements js_library.JSObjectInterfacesDom {
  MessagePortImpl.internal_() : super.internal_();
  get runtimeType => MessagePort;
  toString() => super.toString();
}
@patch class MetaElement {
  static Type get instanceRuntimeType => MetaElementImpl;

}
class MetaElementImpl extends MetaElement implements js_library.JSObjectInterfacesDom {
  MetaElementImpl.internal_() : super.internal_();
  get runtimeType => MetaElement;
  toString() => super.toString();
}
@patch class Metadata {
  static Type get instanceRuntimeType => MetadataImpl;

}
class MetadataImpl extends Metadata implements js_library.JSObjectInterfacesDom {
  MetadataImpl.internal_() : super.internal_();
  get runtimeType => Metadata;
  toString() => super.toString();
}
@patch class MeterElement {
  static Type get instanceRuntimeType => MeterElementImpl;

}
class MeterElementImpl extends MeterElement implements js_library.JSObjectInterfacesDom {
  MeterElementImpl.internal_() : super.internal_();
  get runtimeType => MeterElement;
  toString() => super.toString();
}
@patch class MidiAccess {
  static Type get instanceRuntimeType => MidiAccessImpl;

}
class MidiAccessImpl extends MidiAccess implements js_library.JSObjectInterfacesDom {
  MidiAccessImpl.internal_() : super.internal_();
  get runtimeType => MidiAccess;
  toString() => super.toString();
}
@patch class MidiConnectionEvent {
  static Type get instanceRuntimeType => MidiConnectionEventImpl;

}
class MidiConnectionEventImpl extends MidiConnectionEvent implements js_library.JSObjectInterfacesDom {
  MidiConnectionEventImpl.internal_() : super.internal_();
  get runtimeType => MidiConnectionEvent;
  toString() => super.toString();
}
@patch class MidiInput {
  static Type get instanceRuntimeType => MidiInputImpl;

}
class MidiInputImpl extends MidiInput implements js_library.JSObjectInterfacesDom {
  MidiInputImpl.internal_() : super.internal_();
  get runtimeType => MidiInput;
  toString() => super.toString();
}
@patch class MidiInputMap {
  static Type get instanceRuntimeType => MidiInputMapImpl;

}
class MidiInputMapImpl extends MidiInputMap implements js_library.JSObjectInterfacesDom {
  MidiInputMapImpl.internal_() : super.internal_();
  get runtimeType => MidiInputMap;
  toString() => super.toString();
}
@patch class MidiMessageEvent {
  static Type get instanceRuntimeType => MidiMessageEventImpl;

}
class MidiMessageEventImpl extends MidiMessageEvent implements js_library.JSObjectInterfacesDom {
  MidiMessageEventImpl.internal_() : super.internal_();
  get runtimeType => MidiMessageEvent;
  toString() => super.toString();
}
@patch class MidiOutput {
  static Type get instanceRuntimeType => MidiOutputImpl;

}
class MidiOutputImpl extends MidiOutput implements js_library.JSObjectInterfacesDom {
  MidiOutputImpl.internal_() : super.internal_();
  get runtimeType => MidiOutput;
  toString() => super.toString();
}
@patch class MidiOutputMap {
  static Type get instanceRuntimeType => MidiOutputMapImpl;

}
class MidiOutputMapImpl extends MidiOutputMap implements js_library.JSObjectInterfacesDom {
  MidiOutputMapImpl.internal_() : super.internal_();
  get runtimeType => MidiOutputMap;
  toString() => super.toString();
}
@patch class MidiPort {
  static Type get instanceRuntimeType => MidiPortImpl;

}
class MidiPortImpl extends MidiPort implements js_library.JSObjectInterfacesDom {
  MidiPortImpl.internal_() : super.internal_();
  get runtimeType => MidiPort;
  toString() => super.toString();
}
@patch class MimeType {
  static Type get instanceRuntimeType => MimeTypeImpl;

}
class MimeTypeImpl extends MimeType implements js_library.JSObjectInterfacesDom {
  MimeTypeImpl.internal_() : super.internal_();
  get runtimeType => MimeType;
  toString() => super.toString();
}
@patch class MimeTypeArray {
  static Type get instanceRuntimeType => MimeTypeArrayImpl;

}
class MimeTypeArrayImpl extends MimeTypeArray implements js_library.JSObjectInterfacesDom {
  MimeTypeArrayImpl.internal_() : super.internal_();
  get runtimeType => MimeTypeArray;
  toString() => super.toString();
}
@patch class ModElement {
  static Type get instanceRuntimeType => ModElementImpl;

}
class ModElementImpl extends ModElement implements js_library.JSObjectInterfacesDom {
  ModElementImpl.internal_() : super.internal_();
  get runtimeType => ModElement;
  toString() => super.toString();
}
@patch class MouseEvent {
  static Type get instanceRuntimeType => MouseEventImpl;

}
class MouseEventImpl extends MouseEvent implements js_library.JSObjectInterfacesDom {
  MouseEventImpl.internal_() : super.internal_();
  get runtimeType => MouseEvent;
  toString() => super.toString();
}
@patch class MutationObserver {
  static Type get instanceRuntimeType => MutationObserverImpl;

}
class MutationObserverImpl extends MutationObserver implements js_library.JSObjectInterfacesDom {
  MutationObserverImpl.internal_() : super.internal_();
  get runtimeType => MutationObserver;
  toString() => super.toString();
}
@patch class MutationRecord {
  static Type get instanceRuntimeType => MutationRecordImpl;

}
class MutationRecordImpl extends MutationRecord implements js_library.JSObjectInterfacesDom {
  MutationRecordImpl.internal_() : super.internal_();
  get runtimeType => MutationRecord;
  toString() => super.toString();
}
@patch class Navigator {
  static Type get instanceRuntimeType => NavigatorImpl;

}
class NavigatorImpl extends Navigator implements js_library.JSObjectInterfacesDom {
  NavigatorImpl.internal_() : super.internal_();
  get runtimeType => Navigator;
  toString() => super.toString();
}
@patch class NavigatorCpu {
  static Type get instanceRuntimeType => NavigatorCpuImpl;

}
class NavigatorCpuImpl extends NavigatorCpu implements js_library.JSObjectInterfacesDom {
  NavigatorCpuImpl.internal_() : super.internal_();
  get runtimeType => NavigatorCpu;
  toString() => super.toString();
}
@patch class NavigatorID {
  static Type get instanceRuntimeType => NavigatorIDImpl;

}
class NavigatorIDImpl extends NavigatorID implements js_library.JSObjectInterfacesDom {
  NavigatorIDImpl.internal_() : super.internal_();
  get runtimeType => NavigatorID;
  toString() => super.toString();
}
@patch class NavigatorLanguage {
  static Type get instanceRuntimeType => NavigatorLanguageImpl;

}
class NavigatorLanguageImpl extends NavigatorLanguage implements js_library.JSObjectInterfacesDom {
  NavigatorLanguageImpl.internal_() : super.internal_();
  get runtimeType => NavigatorLanguage;
  toString() => super.toString();
}
@patch class NavigatorOnLine {
  static Type get instanceRuntimeType => NavigatorOnLineImpl;

}
class NavigatorOnLineImpl extends NavigatorOnLine implements js_library.JSObjectInterfacesDom {
  NavigatorOnLineImpl.internal_() : super.internal_();
  get runtimeType => NavigatorOnLine;
  toString() => super.toString();
}
@patch class NavigatorStorageUtils {
  static Type get instanceRuntimeType => NavigatorStorageUtilsImpl;

}
class NavigatorStorageUtilsImpl extends NavigatorStorageUtils implements js_library.JSObjectInterfacesDom {
  NavigatorStorageUtilsImpl.internal_() : super.internal_();
  get runtimeType => NavigatorStorageUtils;
  toString() => super.toString();
}
@patch class NavigatorUserMediaError {
  static Type get instanceRuntimeType => NavigatorUserMediaErrorImpl;

}
class NavigatorUserMediaErrorImpl extends NavigatorUserMediaError implements js_library.JSObjectInterfacesDom {
  NavigatorUserMediaErrorImpl.internal_() : super.internal_();
  get runtimeType => NavigatorUserMediaError;
  toString() => super.toString();
}
@patch class NetworkInformation {
  static Type get instanceRuntimeType => NetworkInformationImpl;

}
class NetworkInformationImpl extends NetworkInformation implements js_library.JSObjectInterfacesDom {
  NetworkInformationImpl.internal_() : super.internal_();
  get runtimeType => NetworkInformation;
  toString() => super.toString();
}
@patch class Node {
  static Type get instanceRuntimeType => NodeImpl;

}
class NodeImpl extends Node implements js_library.JSObjectInterfacesDom {
  NodeImpl.internal_() : super.internal_();
  get runtimeType => Node;
  toString() => super.toString();
}
@patch class NodeFilter {
  static Type get instanceRuntimeType => NodeFilterImpl;

}
class NodeFilterImpl extends NodeFilter implements js_library.JSObjectInterfacesDom {
  NodeFilterImpl.internal_() : super.internal_();
  get runtimeType => NodeFilter;
  toString() => super.toString();
}
@patch class NodeIterator {
  static Type get instanceRuntimeType => NodeIteratorImpl;

}
class NodeIteratorImpl extends NodeIterator implements js_library.JSObjectInterfacesDom {
  NodeIteratorImpl.internal_() : super.internal_();
  get runtimeType => NodeIterator;
  toString() => super.toString();
}
@patch class NodeList {
  static Type get instanceRuntimeType => NodeListImpl;

}
class NodeListImpl extends NodeList implements js_library.JSObjectInterfacesDom {
  NodeListImpl.internal_() : super.internal_();
  get runtimeType => NodeList;
  toString() => super.toString();
}
@patch class NonDocumentTypeChildNode {
  static Type get instanceRuntimeType => NonDocumentTypeChildNodeImpl;

}
class NonDocumentTypeChildNodeImpl extends NonDocumentTypeChildNode implements js_library.JSObjectInterfacesDom {
  NonDocumentTypeChildNodeImpl.internal_() : super.internal_();
  get runtimeType => NonDocumentTypeChildNode;
  toString() => super.toString();
}
@patch class NonElementParentNode {
  static Type get instanceRuntimeType => NonElementParentNodeImpl;

}
class NonElementParentNodeImpl extends NonElementParentNode implements js_library.JSObjectInterfacesDom {
  NonElementParentNodeImpl.internal_() : super.internal_();
  get runtimeType => NonElementParentNode;
  toString() => super.toString();
}
@patch class Notification {
  static Type get instanceRuntimeType => NotificationImpl;

}
class NotificationImpl extends Notification implements js_library.JSObjectInterfacesDom {
  NotificationImpl.internal_() : super.internal_();
  get runtimeType => Notification;
  toString() => super.toString();
}
@patch class NotificationEvent {
  static Type get instanceRuntimeType => NotificationEventImpl;

}
class NotificationEventImpl extends NotificationEvent implements js_library.JSObjectInterfacesDom {
  NotificationEventImpl.internal_() : super.internal_();
  get runtimeType => NotificationEvent;
  toString() => super.toString();
}
@patch class NumberValue {
  static Type get instanceRuntimeType => NumberValueImpl;

}
class NumberValueImpl extends NumberValue implements js_library.JSObjectInterfacesDom {
  NumberValueImpl.internal_() : super.internal_();
  get runtimeType => NumberValue;
  toString() => super.toString();
}
@patch class OListElement {
  static Type get instanceRuntimeType => OListElementImpl;

}
class OListElementImpl extends OListElement implements js_library.JSObjectInterfacesDom {
  OListElementImpl.internal_() : super.internal_();
  get runtimeType => OListElement;
  toString() => super.toString();
}
@patch class ObjectElement {
  static Type get instanceRuntimeType => ObjectElementImpl;

}
class ObjectElementImpl extends ObjectElement implements js_library.JSObjectInterfacesDom {
  ObjectElementImpl.internal_() : super.internal_();
  get runtimeType => ObjectElement;
  toString() => super.toString();
}
@patch class OffscreenCanvas {
  static Type get instanceRuntimeType => OffscreenCanvasImpl;

}
class OffscreenCanvasImpl extends OffscreenCanvas implements js_library.JSObjectInterfacesDom {
  OffscreenCanvasImpl.internal_() : super.internal_();
  get runtimeType => OffscreenCanvas;
  toString() => super.toString();
}
@patch class OptGroupElement {
  static Type get instanceRuntimeType => OptGroupElementImpl;

}
class OptGroupElementImpl extends OptGroupElement implements js_library.JSObjectInterfacesDom {
  OptGroupElementImpl.internal_() : super.internal_();
  get runtimeType => OptGroupElement;
  toString() => super.toString();
}
@patch class OptionElement {
  static Type get instanceRuntimeType => OptionElementImpl;

}
class OptionElementImpl extends OptionElement implements js_library.JSObjectInterfacesDom {
  OptionElementImpl.internal_() : super.internal_();
  get runtimeType => OptionElement;
  toString() => super.toString();
}
@patch class OutputElement {
  static Type get instanceRuntimeType => OutputElementImpl;

}
class OutputElementImpl extends OutputElement implements js_library.JSObjectInterfacesDom {
  OutputElementImpl.internal_() : super.internal_();
  get runtimeType => OutputElement;
  toString() => super.toString();
}
@patch class PageTransitionEvent {
  static Type get instanceRuntimeType => PageTransitionEventImpl;

}
class PageTransitionEventImpl extends PageTransitionEvent implements js_library.JSObjectInterfacesDom {
  PageTransitionEventImpl.internal_() : super.internal_();
  get runtimeType => PageTransitionEvent;
  toString() => super.toString();
}
@patch class ParagraphElement {
  static Type get instanceRuntimeType => ParagraphElementImpl;

}
class ParagraphElementImpl extends ParagraphElement implements js_library.JSObjectInterfacesDom {
  ParagraphElementImpl.internal_() : super.internal_();
  get runtimeType => ParagraphElement;
  toString() => super.toString();
}
@patch class ParamElement {
  static Type get instanceRuntimeType => ParamElementImpl;

}
class ParamElementImpl extends ParamElement implements js_library.JSObjectInterfacesDom {
  ParamElementImpl.internal_() : super.internal_();
  get runtimeType => ParamElement;
  toString() => super.toString();
}
@patch class ParentNode {
  static Type get instanceRuntimeType => ParentNodeImpl;

}
class ParentNodeImpl extends ParentNode implements js_library.JSObjectInterfacesDom {
  ParentNodeImpl.internal_() : super.internal_();
  get runtimeType => ParentNode;
  toString() => super.toString();
}
@patch class PasswordCredential {
  static Type get instanceRuntimeType => PasswordCredentialImpl;

}
class PasswordCredentialImpl extends PasswordCredential implements js_library.JSObjectInterfacesDom {
  PasswordCredentialImpl.internal_() : super.internal_();
  get runtimeType => PasswordCredential;
  toString() => super.toString();
}
@patch class Path2D {
  static Type get instanceRuntimeType => Path2DImpl;

}
class Path2DImpl extends Path2D implements js_library.JSObjectInterfacesDom {
  Path2DImpl.internal_() : super.internal_();
  get runtimeType => Path2D;
  toString() => super.toString();
}
@patch class Performance {
  static Type get instanceRuntimeType => PerformanceImpl;

}
class PerformanceImpl extends Performance implements js_library.JSObjectInterfacesDom {
  PerformanceImpl.internal_() : super.internal_();
  get runtimeType => Performance;
  toString() => super.toString();
}
@patch class PerformanceCompositeTiming {
  static Type get instanceRuntimeType => PerformanceCompositeTimingImpl;

}
class PerformanceCompositeTimingImpl extends PerformanceCompositeTiming implements js_library.JSObjectInterfacesDom {
  PerformanceCompositeTimingImpl.internal_() : super.internal_();
  get runtimeType => PerformanceCompositeTiming;
  toString() => super.toString();
}
@patch class PerformanceEntry {
  static Type get instanceRuntimeType => PerformanceEntryImpl;

}
class PerformanceEntryImpl extends PerformanceEntry implements js_library.JSObjectInterfacesDom {
  PerformanceEntryImpl.internal_() : super.internal_();
  get runtimeType => PerformanceEntry;
  toString() => super.toString();
}
@patch class PerformanceMark {
  static Type get instanceRuntimeType => PerformanceMarkImpl;

}
class PerformanceMarkImpl extends PerformanceMark implements js_library.JSObjectInterfacesDom {
  PerformanceMarkImpl.internal_() : super.internal_();
  get runtimeType => PerformanceMark;
  toString() => super.toString();
}
@patch class PerformanceMeasure {
  static Type get instanceRuntimeType => PerformanceMeasureImpl;

}
class PerformanceMeasureImpl extends PerformanceMeasure implements js_library.JSObjectInterfacesDom {
  PerformanceMeasureImpl.internal_() : super.internal_();
  get runtimeType => PerformanceMeasure;
  toString() => super.toString();
}
@patch class PerformanceNavigation {
  static Type get instanceRuntimeType => PerformanceNavigationImpl;

}
class PerformanceNavigationImpl extends PerformanceNavigation implements js_library.JSObjectInterfacesDom {
  PerformanceNavigationImpl.internal_() : super.internal_();
  get runtimeType => PerformanceNavigation;
  toString() => super.toString();
}
@patch class PerformanceObserver {
  static Type get instanceRuntimeType => PerformanceObserverImpl;

}
class PerformanceObserverImpl extends PerformanceObserver implements js_library.JSObjectInterfacesDom {
  PerformanceObserverImpl.internal_() : super.internal_();
  get runtimeType => PerformanceObserver;
  toString() => super.toString();
}
@patch class PerformanceObserverEntryList {
  static Type get instanceRuntimeType => PerformanceObserverEntryListImpl;

}
class PerformanceObserverEntryListImpl extends PerformanceObserverEntryList implements js_library.JSObjectInterfacesDom {
  PerformanceObserverEntryListImpl.internal_() : super.internal_();
  get runtimeType => PerformanceObserverEntryList;
  toString() => super.toString();
}
@patch class PerformanceRenderTiming {
  static Type get instanceRuntimeType => PerformanceRenderTimingImpl;

}
class PerformanceRenderTimingImpl extends PerformanceRenderTiming implements js_library.JSObjectInterfacesDom {
  PerformanceRenderTimingImpl.internal_() : super.internal_();
  get runtimeType => PerformanceRenderTiming;
  toString() => super.toString();
}
@patch class PerformanceResourceTiming {
  static Type get instanceRuntimeType => PerformanceResourceTimingImpl;

}
class PerformanceResourceTimingImpl extends PerformanceResourceTiming implements js_library.JSObjectInterfacesDom {
  PerformanceResourceTimingImpl.internal_() : super.internal_();
  get runtimeType => PerformanceResourceTiming;
  toString() => super.toString();
}
@patch class PerformanceTiming {
  static Type get instanceRuntimeType => PerformanceTimingImpl;

}
class PerformanceTimingImpl extends PerformanceTiming implements js_library.JSObjectInterfacesDom {
  PerformanceTimingImpl.internal_() : super.internal_();
  get runtimeType => PerformanceTiming;
  toString() => super.toString();
}
@patch class PermissionStatus {
  static Type get instanceRuntimeType => PermissionStatusImpl;

}
class PermissionStatusImpl extends PermissionStatus implements js_library.JSObjectInterfacesDom {
  PermissionStatusImpl.internal_() : super.internal_();
  get runtimeType => PermissionStatus;
  toString() => super.toString();
}
@patch class Permissions {
  static Type get instanceRuntimeType => PermissionsImpl;

}
class PermissionsImpl extends Permissions implements js_library.JSObjectInterfacesDom {
  PermissionsImpl.internal_() : super.internal_();
  get runtimeType => Permissions;
  toString() => super.toString();
}
@patch class Perspective {
  static Type get instanceRuntimeType => PerspectiveImpl;

}
class PerspectiveImpl extends Perspective implements js_library.JSObjectInterfacesDom {
  PerspectiveImpl.internal_() : super.internal_();
  get runtimeType => Perspective;
  toString() => super.toString();
}
@patch class PictureElement {
  static Type get instanceRuntimeType => PictureElementImpl;

}
class PictureElementImpl extends PictureElement implements js_library.JSObjectInterfacesDom {
  PictureElementImpl.internal_() : super.internal_();
  get runtimeType => PictureElement;
  toString() => super.toString();
}
@patch class Plugin {
  static Type get instanceRuntimeType => PluginImpl;

}
class PluginImpl extends Plugin implements js_library.JSObjectInterfacesDom {
  PluginImpl.internal_() : super.internal_();
  get runtimeType => Plugin;
  toString() => super.toString();
}
@patch class PluginArray {
  static Type get instanceRuntimeType => PluginArrayImpl;

}
class PluginArrayImpl extends PluginArray implements js_library.JSObjectInterfacesDom {
  PluginArrayImpl.internal_() : super.internal_();
  get runtimeType => PluginArray;
  toString() => super.toString();
}
@patch class PointerEvent {
  static Type get instanceRuntimeType => PointerEventImpl;

}
class PointerEventImpl extends PointerEvent implements js_library.JSObjectInterfacesDom {
  PointerEventImpl.internal_() : super.internal_();
  get runtimeType => PointerEvent;
  toString() => super.toString();
}
@patch class PopStateEvent {
  static Type get instanceRuntimeType => PopStateEventImpl;

}
class PopStateEventImpl extends PopStateEvent implements js_library.JSObjectInterfacesDom {
  PopStateEventImpl.internal_() : super.internal_();
  get runtimeType => PopStateEvent;
  toString() => super.toString();
}
@patch class PositionError {
  static Type get instanceRuntimeType => PositionErrorImpl;

}
class PositionErrorImpl extends PositionError implements js_library.JSObjectInterfacesDom {
  PositionErrorImpl.internal_() : super.internal_();
  get runtimeType => PositionError;
  toString() => super.toString();
}
@patch class PositionSensorVRDevice {
  static Type get instanceRuntimeType => PositionSensorVRDeviceImpl;

}
class PositionSensorVRDeviceImpl extends PositionSensorVRDevice implements js_library.JSObjectInterfacesDom {
  PositionSensorVRDeviceImpl.internal_() : super.internal_();
  get runtimeType => PositionSensorVRDevice;
  toString() => super.toString();
}
@patch class PositionValue {
  static Type get instanceRuntimeType => PositionValueImpl;

}
class PositionValueImpl extends PositionValue implements js_library.JSObjectInterfacesDom {
  PositionValueImpl.internal_() : super.internal_();
  get runtimeType => PositionValue;
  toString() => super.toString();
}
@patch class PreElement {
  static Type get instanceRuntimeType => PreElementImpl;

}
class PreElementImpl extends PreElement implements js_library.JSObjectInterfacesDom {
  PreElementImpl.internal_() : super.internal_();
  get runtimeType => PreElement;
  toString() => super.toString();
}
@patch class Presentation {
  static Type get instanceRuntimeType => PresentationImpl;

}
class PresentationImpl extends Presentation implements js_library.JSObjectInterfacesDom {
  PresentationImpl.internal_() : super.internal_();
  get runtimeType => Presentation;
  toString() => super.toString();
}
@patch class PresentationAvailability {
  static Type get instanceRuntimeType => PresentationAvailabilityImpl;

}
class PresentationAvailabilityImpl extends PresentationAvailability implements js_library.JSObjectInterfacesDom {
  PresentationAvailabilityImpl.internal_() : super.internal_();
  get runtimeType => PresentationAvailability;
  toString() => super.toString();
}
@patch class PresentationConnection {
  static Type get instanceRuntimeType => PresentationConnectionImpl;

}
class PresentationConnectionImpl extends PresentationConnection implements js_library.JSObjectInterfacesDom {
  PresentationConnectionImpl.internal_() : super.internal_();
  get runtimeType => PresentationConnection;
  toString() => super.toString();
}
@patch class PresentationConnectionAvailableEvent {
  static Type get instanceRuntimeType => PresentationConnectionAvailableEventImpl;

}
class PresentationConnectionAvailableEventImpl extends PresentationConnectionAvailableEvent implements js_library.JSObjectInterfacesDom {
  PresentationConnectionAvailableEventImpl.internal_() : super.internal_();
  get runtimeType => PresentationConnectionAvailableEvent;
  toString() => super.toString();
}
@patch class PresentationConnectionCloseEvent {
  static Type get instanceRuntimeType => PresentationConnectionCloseEventImpl;

}
class PresentationConnectionCloseEventImpl extends PresentationConnectionCloseEvent implements js_library.JSObjectInterfacesDom {
  PresentationConnectionCloseEventImpl.internal_() : super.internal_();
  get runtimeType => PresentationConnectionCloseEvent;
  toString() => super.toString();
}
@patch class PresentationReceiver {
  static Type get instanceRuntimeType => PresentationReceiverImpl;

}
class PresentationReceiverImpl extends PresentationReceiver implements js_library.JSObjectInterfacesDom {
  PresentationReceiverImpl.internal_() : super.internal_();
  get runtimeType => PresentationReceiver;
  toString() => super.toString();
}
@patch class PresentationRequest {
  static Type get instanceRuntimeType => PresentationRequestImpl;

}
class PresentationRequestImpl extends PresentationRequest implements js_library.JSObjectInterfacesDom {
  PresentationRequestImpl.internal_() : super.internal_();
  get runtimeType => PresentationRequest;
  toString() => super.toString();
}
@patch class ProcessingInstruction {
  static Type get instanceRuntimeType => ProcessingInstructionImpl;

}
class ProcessingInstructionImpl extends ProcessingInstruction implements js_library.JSObjectInterfacesDom {
  ProcessingInstructionImpl.internal_() : super.internal_();
  get runtimeType => ProcessingInstruction;
  toString() => super.toString();
}
@patch class ProgressElement {
  static Type get instanceRuntimeType => ProgressElementImpl;

}
class ProgressElementImpl extends ProgressElement implements js_library.JSObjectInterfacesDom {
  ProgressElementImpl.internal_() : super.internal_();
  get runtimeType => ProgressElement;
  toString() => super.toString();
}
@patch class ProgressEvent {
  static Type get instanceRuntimeType => ProgressEventImpl;

}
class ProgressEventImpl extends ProgressEvent implements js_library.JSObjectInterfacesDom {
  ProgressEventImpl.internal_() : super.internal_();
  get runtimeType => ProgressEvent;
  toString() => super.toString();
}
@patch class PromiseRejectionEvent {
  static Type get instanceRuntimeType => PromiseRejectionEventImpl;

}
class PromiseRejectionEventImpl extends PromiseRejectionEvent implements js_library.JSObjectInterfacesDom {
  PromiseRejectionEventImpl.internal_() : super.internal_();
  get runtimeType => PromiseRejectionEvent;
  toString() => super.toString();
}
@patch class PushEvent {
  static Type get instanceRuntimeType => PushEventImpl;

}
class PushEventImpl extends PushEvent implements js_library.JSObjectInterfacesDom {
  PushEventImpl.internal_() : super.internal_();
  get runtimeType => PushEvent;
  toString() => super.toString();
}
@patch class PushManager {
  static Type get instanceRuntimeType => PushManagerImpl;

}
class PushManagerImpl extends PushManager implements js_library.JSObjectInterfacesDom {
  PushManagerImpl.internal_() : super.internal_();
  get runtimeType => PushManager;
  toString() => super.toString();
}
@patch class PushMessageData {
  static Type get instanceRuntimeType => PushMessageDataImpl;

}
class PushMessageDataImpl extends PushMessageData implements js_library.JSObjectInterfacesDom {
  PushMessageDataImpl.internal_() : super.internal_();
  get runtimeType => PushMessageData;
  toString() => super.toString();
}
@patch class PushSubscription {
  static Type get instanceRuntimeType => PushSubscriptionImpl;

}
class PushSubscriptionImpl extends PushSubscription implements js_library.JSObjectInterfacesDom {
  PushSubscriptionImpl.internal_() : super.internal_();
  get runtimeType => PushSubscription;
  toString() => super.toString();
}
@patch class QuoteElement {
  static Type get instanceRuntimeType => QuoteElementImpl;

}
class QuoteElementImpl extends QuoteElement implements js_library.JSObjectInterfacesDom {
  QuoteElementImpl.internal_() : super.internal_();
  get runtimeType => QuoteElement;
  toString() => super.toString();
}
@patch class Range {
  static Type get instanceRuntimeType => RangeImpl;

}
class RangeImpl extends Range implements js_library.JSObjectInterfacesDom {
  RangeImpl.internal_() : super.internal_();
  get runtimeType => Range;
  toString() => super.toString();
}
@patch class ReadableByteStream {
  static Type get instanceRuntimeType => ReadableByteStreamImpl;

}
class ReadableByteStreamImpl extends ReadableByteStream implements js_library.JSObjectInterfacesDom {
  ReadableByteStreamImpl.internal_() : super.internal_();
  get runtimeType => ReadableByteStream;
  toString() => super.toString();
}
@patch class ReadableByteStreamReader {
  static Type get instanceRuntimeType => ReadableByteStreamReaderImpl;

}
class ReadableByteStreamReaderImpl extends ReadableByteStreamReader implements js_library.JSObjectInterfacesDom {
  ReadableByteStreamReaderImpl.internal_() : super.internal_();
  get runtimeType => ReadableByteStreamReader;
  toString() => super.toString();
}
@patch class ReadableStreamReader {
  static Type get instanceRuntimeType => ReadableStreamReaderImpl;

}
class ReadableStreamReaderImpl extends ReadableStreamReader implements js_library.JSObjectInterfacesDom {
  ReadableStreamReaderImpl.internal_() : super.internal_();
  get runtimeType => ReadableStreamReader;
  toString() => super.toString();
}
@patch class RelatedEvent {
  static Type get instanceRuntimeType => RelatedEventImpl;

}
class RelatedEventImpl extends RelatedEvent implements js_library.JSObjectInterfacesDom {
  RelatedEventImpl.internal_() : super.internal_();
  get runtimeType => RelatedEvent;
  toString() => super.toString();
}
@patch class Rotation {
  static Type get instanceRuntimeType => RotationImpl;

}
class RotationImpl extends Rotation implements js_library.JSObjectInterfacesDom {
  RotationImpl.internal_() : super.internal_();
  get runtimeType => Rotation;
  toString() => super.toString();
}
@patch class RtcCertificate {
  static Type get instanceRuntimeType => RtcCertificateImpl;

}
class RtcCertificateImpl extends RtcCertificate implements js_library.JSObjectInterfacesDom {
  RtcCertificateImpl.internal_() : super.internal_();
  get runtimeType => RtcCertificate;
  toString() => super.toString();
}
@patch class RtcDataChannel {
  static Type get instanceRuntimeType => RtcDataChannelImpl;

}
class RtcDataChannelImpl extends RtcDataChannel implements js_library.JSObjectInterfacesDom {
  RtcDataChannelImpl.internal_() : super.internal_();
  get runtimeType => RtcDataChannel;
  toString() => super.toString();
}
@patch class RtcDataChannelEvent {
  static Type get instanceRuntimeType => RtcDataChannelEventImpl;

}
class RtcDataChannelEventImpl extends RtcDataChannelEvent implements js_library.JSObjectInterfacesDom {
  RtcDataChannelEventImpl.internal_() : super.internal_();
  get runtimeType => RtcDataChannelEvent;
  toString() => super.toString();
}
@patch class RtcDtmfSender {
  static Type get instanceRuntimeType => RtcDtmfSenderImpl;

}
class RtcDtmfSenderImpl extends RtcDtmfSender implements js_library.JSObjectInterfacesDom {
  RtcDtmfSenderImpl.internal_() : super.internal_();
  get runtimeType => RtcDtmfSender;
  toString() => super.toString();
}
@patch class RtcDtmfToneChangeEvent {
  static Type get instanceRuntimeType => RtcDtmfToneChangeEventImpl;

}
class RtcDtmfToneChangeEventImpl extends RtcDtmfToneChangeEvent implements js_library.JSObjectInterfacesDom {
  RtcDtmfToneChangeEventImpl.internal_() : super.internal_();
  get runtimeType => RtcDtmfToneChangeEvent;
  toString() => super.toString();
}
@patch class RtcIceCandidate {
  static Type get instanceRuntimeType => RtcIceCandidateImpl;

}
class RtcIceCandidateImpl extends RtcIceCandidate implements js_library.JSObjectInterfacesDom {
  RtcIceCandidateImpl.internal_() : super.internal_();
  get runtimeType => RtcIceCandidate;
  toString() => super.toString();
}
@patch class RtcIceCandidateEvent {
  static Type get instanceRuntimeType => RtcIceCandidateEventImpl;

}
class RtcIceCandidateEventImpl extends RtcIceCandidateEvent implements js_library.JSObjectInterfacesDom {
  RtcIceCandidateEventImpl.internal_() : super.internal_();
  get runtimeType => RtcIceCandidateEvent;
  toString() => super.toString();
}
@patch class RtcPeerConnection {
  static Type get instanceRuntimeType => RtcPeerConnectionImpl;

}
class RtcPeerConnectionImpl extends RtcPeerConnection implements js_library.JSObjectInterfacesDom {
  RtcPeerConnectionImpl.internal_() : super.internal_();
  get runtimeType => RtcPeerConnection;
  toString() => super.toString();
}
@patch class RtcSessionDescription {
  static Type get instanceRuntimeType => RtcSessionDescriptionImpl;

}
class RtcSessionDescriptionImpl extends RtcSessionDescription implements js_library.JSObjectInterfacesDom {
  RtcSessionDescriptionImpl.internal_() : super.internal_();
  get runtimeType => RtcSessionDescription;
  toString() => super.toString();
}
@patch class RtcStatsReport {
  static Type get instanceRuntimeType => RtcStatsReportImpl;

}
class RtcStatsReportImpl extends RtcStatsReport implements js_library.JSObjectInterfacesDom {
  RtcStatsReportImpl.internal_() : super.internal_();
  get runtimeType => RtcStatsReport;
  toString() => super.toString();
}
@patch class RtcStatsResponse {
  static Type get instanceRuntimeType => RtcStatsResponseImpl;

}
class RtcStatsResponseImpl extends RtcStatsResponse implements js_library.JSObjectInterfacesDom {
  RtcStatsResponseImpl.internal_() : super.internal_();
  get runtimeType => RtcStatsResponse;
  toString() => super.toString();
}
@patch class Screen {
  static Type get instanceRuntimeType => ScreenImpl;

}
class ScreenImpl extends Screen implements js_library.JSObjectInterfacesDom {
  ScreenImpl.internal_() : super.internal_();
  get runtimeType => Screen;
  toString() => super.toString();
}
@patch class ScreenOrientation {
  static Type get instanceRuntimeType => ScreenOrientationImpl;

}
class ScreenOrientationImpl extends ScreenOrientation implements js_library.JSObjectInterfacesDom {
  ScreenOrientationImpl.internal_() : super.internal_();
  get runtimeType => ScreenOrientation;
  toString() => super.toString();
}
@patch class ScriptElement {
  static Type get instanceRuntimeType => ScriptElementImpl;

}
class ScriptElementImpl extends ScriptElement implements js_library.JSObjectInterfacesDom {
  ScriptElementImpl.internal_() : super.internal_();
  get runtimeType => ScriptElement;
  toString() => super.toString();
}
@patch class ScrollState {
  static Type get instanceRuntimeType => ScrollStateImpl;

}
class ScrollStateImpl extends ScrollState implements js_library.JSObjectInterfacesDom {
  ScrollStateImpl.internal_() : super.internal_();
  get runtimeType => ScrollState;
  toString() => super.toString();
}
@patch class SecurityPolicyViolationEvent {
  static Type get instanceRuntimeType => SecurityPolicyViolationEventImpl;

}
class SecurityPolicyViolationEventImpl extends SecurityPolicyViolationEvent implements js_library.JSObjectInterfacesDom {
  SecurityPolicyViolationEventImpl.internal_() : super.internal_();
  get runtimeType => SecurityPolicyViolationEvent;
  toString() => super.toString();
}
@patch class SelectElement {
  static Type get instanceRuntimeType => SelectElementImpl;

}
class SelectElementImpl extends SelectElement implements js_library.JSObjectInterfacesDom {
  SelectElementImpl.internal_() : super.internal_();
  get runtimeType => SelectElement;
  toString() => super.toString();
}
@patch class Selection {
  static Type get instanceRuntimeType => SelectionImpl;

}
class SelectionImpl extends Selection implements js_library.JSObjectInterfacesDom {
  SelectionImpl.internal_() : super.internal_();
  get runtimeType => Selection;
  toString() => super.toString();
}
@patch class ServicePort {
  static Type get instanceRuntimeType => ServicePortImpl;

}
class ServicePortImpl extends ServicePort implements js_library.JSObjectInterfacesDom {
  ServicePortImpl.internal_() : super.internal_();
  get runtimeType => ServicePort;
  toString() => super.toString();
}
@patch class ServicePortCollection {
  static Type get instanceRuntimeType => ServicePortCollectionImpl;

}
class ServicePortCollectionImpl extends ServicePortCollection implements js_library.JSObjectInterfacesDom {
  ServicePortCollectionImpl.internal_() : super.internal_();
  get runtimeType => ServicePortCollection;
  toString() => super.toString();
}
@patch class ServicePortConnectEvent {
  static Type get instanceRuntimeType => ServicePortConnectEventImpl;

}
class ServicePortConnectEventImpl extends ServicePortConnectEvent implements js_library.JSObjectInterfacesDom {
  ServicePortConnectEventImpl.internal_() : super.internal_();
  get runtimeType => ServicePortConnectEvent;
  toString() => super.toString();
}
@patch class ServiceWorkerContainer {
  static Type get instanceRuntimeType => ServiceWorkerContainerImpl;

}
class ServiceWorkerContainerImpl extends ServiceWorkerContainer implements js_library.JSObjectInterfacesDom {
  ServiceWorkerContainerImpl.internal_() : super.internal_();
  get runtimeType => ServiceWorkerContainer;
  toString() => super.toString();
}
@patch class ServiceWorkerGlobalScope {
  static Type get instanceRuntimeType => ServiceWorkerGlobalScopeImpl;

}
class ServiceWorkerGlobalScopeImpl extends ServiceWorkerGlobalScope implements js_library.JSObjectInterfacesDom {
  ServiceWorkerGlobalScopeImpl.internal_() : super.internal_();
  get runtimeType => ServiceWorkerGlobalScope;
  toString() => super.toString();
}
@patch class ServiceWorkerMessageEvent {
  static Type get instanceRuntimeType => ServiceWorkerMessageEventImpl;

}
class ServiceWorkerMessageEventImpl extends ServiceWorkerMessageEvent implements js_library.JSObjectInterfacesDom {
  ServiceWorkerMessageEventImpl.internal_() : super.internal_();
  get runtimeType => ServiceWorkerMessageEvent;
  toString() => super.toString();
}
@patch class ServiceWorkerRegistration {
  static Type get instanceRuntimeType => ServiceWorkerRegistrationImpl;

}
class ServiceWorkerRegistrationImpl extends ServiceWorkerRegistration implements js_library.JSObjectInterfacesDom {
  ServiceWorkerRegistrationImpl.internal_() : super.internal_();
  get runtimeType => ServiceWorkerRegistration;
  toString() => super.toString();
}
@patch class ShadowElement {
  static Type get instanceRuntimeType => ShadowElementImpl;

}
class ShadowElementImpl extends ShadowElement implements js_library.JSObjectInterfacesDom {
  ShadowElementImpl.internal_() : super.internal_();
  get runtimeType => ShadowElement;
  toString() => super.toString();
}
@patch class ShadowRoot {
  static Type get instanceRuntimeType => ShadowRootImpl;

}
class ShadowRootImpl extends ShadowRoot implements js_library.JSObjectInterfacesDom {
  ShadowRootImpl.internal_() : super.internal_();
  get runtimeType => ShadowRoot;
  toString() => super.toString();
}
@patch class SharedArrayBuffer {
  static Type get instanceRuntimeType => SharedArrayBufferImpl;

}
class SharedArrayBufferImpl extends SharedArrayBuffer implements js_library.JSObjectInterfacesDom {
  SharedArrayBufferImpl.internal_() : super.internal_();
  get runtimeType => SharedArrayBuffer;
  toString() => super.toString();
}
@patch class SharedWorker {
  static Type get instanceRuntimeType => SharedWorkerImpl;

}
class SharedWorkerImpl extends SharedWorker implements js_library.JSObjectInterfacesDom {
  SharedWorkerImpl.internal_() : super.internal_();
  get runtimeType => SharedWorker;
  toString() => super.toString();
}
@patch class SharedWorkerGlobalScope {
  static Type get instanceRuntimeType => SharedWorkerGlobalScopeImpl;

}
class SharedWorkerGlobalScopeImpl extends SharedWorkerGlobalScope implements js_library.JSObjectInterfacesDom {
  SharedWorkerGlobalScopeImpl.internal_() : super.internal_();
  get runtimeType => SharedWorkerGlobalScope;
  toString() => super.toString();
}
@patch class SimpleLength {
  static Type get instanceRuntimeType => SimpleLengthImpl;

}
class SimpleLengthImpl extends SimpleLength implements js_library.JSObjectInterfacesDom {
  SimpleLengthImpl.internal_() : super.internal_();
  get runtimeType => SimpleLength;
  toString() => super.toString();
}
@patch class Skew {
  static Type get instanceRuntimeType => SkewImpl;

}
class SkewImpl extends Skew implements js_library.JSObjectInterfacesDom {
  SkewImpl.internal_() : super.internal_();
  get runtimeType => Skew;
  toString() => super.toString();
}
@patch class SlotElement {
  static Type get instanceRuntimeType => SlotElementImpl;

}
class SlotElementImpl extends SlotElement implements js_library.JSObjectInterfacesDom {
  SlotElementImpl.internal_() : super.internal_();
  get runtimeType => SlotElement;
  toString() => super.toString();
}
@patch class SourceBuffer {
  static Type get instanceRuntimeType => SourceBufferImpl;

}
class SourceBufferImpl extends SourceBuffer implements js_library.JSObjectInterfacesDom {
  SourceBufferImpl.internal_() : super.internal_();
  get runtimeType => SourceBuffer;
  toString() => super.toString();
}
@patch class SourceBufferList {
  static Type get instanceRuntimeType => SourceBufferListImpl;

}
class SourceBufferListImpl extends SourceBufferList implements js_library.JSObjectInterfacesDom {
  SourceBufferListImpl.internal_() : super.internal_();
  get runtimeType => SourceBufferList;
  toString() => super.toString();
}
@patch class SourceElement {
  static Type get instanceRuntimeType => SourceElementImpl;

}
class SourceElementImpl extends SourceElement implements js_library.JSObjectInterfacesDom {
  SourceElementImpl.internal_() : super.internal_();
  get runtimeType => SourceElement;
  toString() => super.toString();
}
@patch class SourceInfo {
  static Type get instanceRuntimeType => SourceInfoImpl;

}
class SourceInfoImpl extends SourceInfo implements js_library.JSObjectInterfacesDom {
  SourceInfoImpl.internal_() : super.internal_();
  get runtimeType => SourceInfo;
  toString() => super.toString();
}
@patch class SpanElement {
  static Type get instanceRuntimeType => SpanElementImpl;

}
class SpanElementImpl extends SpanElement implements js_library.JSObjectInterfacesDom {
  SpanElementImpl.internal_() : super.internal_();
  get runtimeType => SpanElement;
  toString() => super.toString();
}
@patch class SpeechGrammar {
  static Type get instanceRuntimeType => SpeechGrammarImpl;

}
class SpeechGrammarImpl extends SpeechGrammar implements js_library.JSObjectInterfacesDom {
  SpeechGrammarImpl.internal_() : super.internal_();
  get runtimeType => SpeechGrammar;
  toString() => super.toString();
}
@patch class SpeechGrammarList {
  static Type get instanceRuntimeType => SpeechGrammarListImpl;

}
class SpeechGrammarListImpl extends SpeechGrammarList implements js_library.JSObjectInterfacesDom {
  SpeechGrammarListImpl.internal_() : super.internal_();
  get runtimeType => SpeechGrammarList;
  toString() => super.toString();
}
@patch class SpeechRecognition {
  static Type get instanceRuntimeType => SpeechRecognitionImpl;

}
class SpeechRecognitionImpl extends SpeechRecognition implements js_library.JSObjectInterfacesDom {
  SpeechRecognitionImpl.internal_() : super.internal_();
  get runtimeType => SpeechRecognition;
  toString() => super.toString();
}
@patch class SpeechRecognitionAlternative {
  static Type get instanceRuntimeType => SpeechRecognitionAlternativeImpl;

}
class SpeechRecognitionAlternativeImpl extends SpeechRecognitionAlternative implements js_library.JSObjectInterfacesDom {
  SpeechRecognitionAlternativeImpl.internal_() : super.internal_();
  get runtimeType => SpeechRecognitionAlternative;
  toString() => super.toString();
}
@patch class SpeechRecognitionError {
  static Type get instanceRuntimeType => SpeechRecognitionErrorImpl;

}
class SpeechRecognitionErrorImpl extends SpeechRecognitionError implements js_library.JSObjectInterfacesDom {
  SpeechRecognitionErrorImpl.internal_() : super.internal_();
  get runtimeType => SpeechRecognitionError;
  toString() => super.toString();
}
@patch class SpeechRecognitionEvent {
  static Type get instanceRuntimeType => SpeechRecognitionEventImpl;

}
class SpeechRecognitionEventImpl extends SpeechRecognitionEvent implements js_library.JSObjectInterfacesDom {
  SpeechRecognitionEventImpl.internal_() : super.internal_();
  get runtimeType => SpeechRecognitionEvent;
  toString() => super.toString();
}
@patch class SpeechRecognitionResult {
  static Type get instanceRuntimeType => SpeechRecognitionResultImpl;

}
class SpeechRecognitionResultImpl extends SpeechRecognitionResult implements js_library.JSObjectInterfacesDom {
  SpeechRecognitionResultImpl.internal_() : super.internal_();
  get runtimeType => SpeechRecognitionResult;
  toString() => super.toString();
}
@patch class SpeechSynthesis {
  static Type get instanceRuntimeType => SpeechSynthesisImpl;

}
class SpeechSynthesisImpl extends SpeechSynthesis implements js_library.JSObjectInterfacesDom {
  SpeechSynthesisImpl.internal_() : super.internal_();
  get runtimeType => SpeechSynthesis;
  toString() => super.toString();
}
@patch class SpeechSynthesisEvent {
  static Type get instanceRuntimeType => SpeechSynthesisEventImpl;

}
class SpeechSynthesisEventImpl extends SpeechSynthesisEvent implements js_library.JSObjectInterfacesDom {
  SpeechSynthesisEventImpl.internal_() : super.internal_();
  get runtimeType => SpeechSynthesisEvent;
  toString() => super.toString();
}
@patch class SpeechSynthesisUtterance {
  static Type get instanceRuntimeType => SpeechSynthesisUtteranceImpl;

}
class SpeechSynthesisUtteranceImpl extends SpeechSynthesisUtterance implements js_library.JSObjectInterfacesDom {
  SpeechSynthesisUtteranceImpl.internal_() : super.internal_();
  get runtimeType => SpeechSynthesisUtterance;
  toString() => super.toString();
}
@patch class SpeechSynthesisVoice {
  static Type get instanceRuntimeType => SpeechSynthesisVoiceImpl;

}
class SpeechSynthesisVoiceImpl extends SpeechSynthesisVoice implements js_library.JSObjectInterfacesDom {
  SpeechSynthesisVoiceImpl.internal_() : super.internal_();
  get runtimeType => SpeechSynthesisVoice;
  toString() => super.toString();
}
@patch class Storage {
  static Type get instanceRuntimeType => StorageImpl;

}
class StorageImpl extends Storage implements js_library.JSObjectInterfacesDom {
  StorageImpl.internal_() : super.internal_();
  get runtimeType => Storage;
  toString() => super.toString();
}
@patch class StorageEvent {
  static Type get instanceRuntimeType => StorageEventImpl;

}
class StorageEventImpl extends StorageEvent implements js_library.JSObjectInterfacesDom {
  StorageEventImpl.internal_() : super.internal_();
  get runtimeType => StorageEvent;
  toString() => super.toString();
}
@patch class StorageInfo {
  static Type get instanceRuntimeType => StorageInfoImpl;

}
class StorageInfoImpl extends StorageInfo implements js_library.JSObjectInterfacesDom {
  StorageInfoImpl.internal_() : super.internal_();
  get runtimeType => StorageInfo;
  toString() => super.toString();
}
@patch class StorageManager {
  static Type get instanceRuntimeType => StorageManagerImpl;

}
class StorageManagerImpl extends StorageManager implements js_library.JSObjectInterfacesDom {
  StorageManagerImpl.internal_() : super.internal_();
  get runtimeType => StorageManager;
  toString() => super.toString();
}
@patch class StorageQuota {
  static Type get instanceRuntimeType => StorageQuotaImpl;

}
class StorageQuotaImpl extends StorageQuota implements js_library.JSObjectInterfacesDom {
  StorageQuotaImpl.internal_() : super.internal_();
  get runtimeType => StorageQuota;
  toString() => super.toString();
}
@patch class StyleElement {
  static Type get instanceRuntimeType => StyleElementImpl;

}
class StyleElementImpl extends StyleElement implements js_library.JSObjectInterfacesDom {
  StyleElementImpl.internal_() : super.internal_();
  get runtimeType => StyleElement;
  toString() => super.toString();
}
@patch class StyleMedia {
  static Type get instanceRuntimeType => StyleMediaImpl;

}
class StyleMediaImpl extends StyleMedia implements js_library.JSObjectInterfacesDom {
  StyleMediaImpl.internal_() : super.internal_();
  get runtimeType => StyleMedia;
  toString() => super.toString();
}
@patch class StylePropertyMap {
  static Type get instanceRuntimeType => StylePropertyMapImpl;

}
class StylePropertyMapImpl extends StylePropertyMap implements js_library.JSObjectInterfacesDom {
  StylePropertyMapImpl.internal_() : super.internal_();
  get runtimeType => StylePropertyMap;
  toString() => super.toString();
}
@patch class StyleSheet {
  static Type get instanceRuntimeType => StyleSheetImpl;

}
class StyleSheetImpl extends StyleSheet implements js_library.JSObjectInterfacesDom {
  StyleSheetImpl.internal_() : super.internal_();
  get runtimeType => StyleSheet;
  toString() => super.toString();
}
@patch class StyleValue {
  static Type get instanceRuntimeType => StyleValueImpl;

}
class StyleValueImpl extends StyleValue implements js_library.JSObjectInterfacesDom {
  StyleValueImpl.internal_() : super.internal_();
  get runtimeType => StyleValue;
  toString() => super.toString();
}
@patch class SyncEvent {
  static Type get instanceRuntimeType => SyncEventImpl;

}
class SyncEventImpl extends SyncEvent implements js_library.JSObjectInterfacesDom {
  SyncEventImpl.internal_() : super.internal_();
  get runtimeType => SyncEvent;
  toString() => super.toString();
}
@patch class SyncManager {
  static Type get instanceRuntimeType => SyncManagerImpl;

}
class SyncManagerImpl extends SyncManager implements js_library.JSObjectInterfacesDom {
  SyncManagerImpl.internal_() : super.internal_();
  get runtimeType => SyncManager;
  toString() => super.toString();
}
@patch class TableCaptionElement {
  static Type get instanceRuntimeType => TableCaptionElementImpl;

}
class TableCaptionElementImpl extends TableCaptionElement implements js_library.JSObjectInterfacesDom {
  TableCaptionElementImpl.internal_() : super.internal_();
  get runtimeType => TableCaptionElement;
  toString() => super.toString();
}
@patch class TableCellElement {
  static Type get instanceRuntimeType => TableCellElementImpl;

}
class TableCellElementImpl extends TableCellElement implements js_library.JSObjectInterfacesDom {
  TableCellElementImpl.internal_() : super.internal_();
  get runtimeType => TableCellElement;
  toString() => super.toString();
}
@patch class TableColElement {
  static Type get instanceRuntimeType => TableColElementImpl;

}
class TableColElementImpl extends TableColElement implements js_library.JSObjectInterfacesDom {
  TableColElementImpl.internal_() : super.internal_();
  get runtimeType => TableColElement;
  toString() => super.toString();
}
@patch class TableElement {
  static Type get instanceRuntimeType => TableElementImpl;

}
class TableElementImpl extends TableElement implements js_library.JSObjectInterfacesDom {
  TableElementImpl.internal_() : super.internal_();
  get runtimeType => TableElement;
  toString() => super.toString();
}
@patch class TableRowElement {
  static Type get instanceRuntimeType => TableRowElementImpl;

}
class TableRowElementImpl extends TableRowElement implements js_library.JSObjectInterfacesDom {
  TableRowElementImpl.internal_() : super.internal_();
  get runtimeType => TableRowElement;
  toString() => super.toString();
}
@patch class TableSectionElement {
  static Type get instanceRuntimeType => TableSectionElementImpl;

}
class TableSectionElementImpl extends TableSectionElement implements js_library.JSObjectInterfacesDom {
  TableSectionElementImpl.internal_() : super.internal_();
  get runtimeType => TableSectionElement;
  toString() => super.toString();
}
@patch class TemplateElement {
  static Type get instanceRuntimeType => TemplateElementImpl;

}
class TemplateElementImpl extends TemplateElement implements js_library.JSObjectInterfacesDom {
  TemplateElementImpl.internal_() : super.internal_();
  get runtimeType => TemplateElement;
  toString() => super.toString();
}
@patch class Text {
  static Type get instanceRuntimeType => TextImpl;

}
class TextImpl extends Text implements js_library.JSObjectInterfacesDom {
  TextImpl.internal_() : super.internal_();
  get runtimeType => Text;
  toString() => super.toString();
}
@patch class TextAreaElement {
  static Type get instanceRuntimeType => TextAreaElementImpl;

}
class TextAreaElementImpl extends TextAreaElement implements js_library.JSObjectInterfacesDom {
  TextAreaElementImpl.internal_() : super.internal_();
  get runtimeType => TextAreaElement;
  toString() => super.toString();
}
@patch class TextEvent {
  static Type get instanceRuntimeType => TextEventImpl;

}
class TextEventImpl extends TextEvent implements js_library.JSObjectInterfacesDom {
  TextEventImpl.internal_() : super.internal_();
  get runtimeType => TextEvent;
  toString() => super.toString();
}
@patch class TextMetrics {
  static Type get instanceRuntimeType => TextMetricsImpl;

}
class TextMetricsImpl extends TextMetrics implements js_library.JSObjectInterfacesDom {
  TextMetricsImpl.internal_() : super.internal_();
  get runtimeType => TextMetrics;
  toString() => super.toString();
}
@patch class TextTrack {
  static Type get instanceRuntimeType => TextTrackImpl;

}
class TextTrackImpl extends TextTrack implements js_library.JSObjectInterfacesDom {
  TextTrackImpl.internal_() : super.internal_();
  get runtimeType => TextTrack;
  toString() => super.toString();
}
@patch class TextTrackCue {
  static Type get instanceRuntimeType => TextTrackCueImpl;

}
class TextTrackCueImpl extends TextTrackCue implements js_library.JSObjectInterfacesDom {
  TextTrackCueImpl.internal_() : super.internal_();
  get runtimeType => TextTrackCue;
  toString() => super.toString();
}
@patch class TextTrackCueList {
  static Type get instanceRuntimeType => TextTrackCueListImpl;

}
class TextTrackCueListImpl extends TextTrackCueList implements js_library.JSObjectInterfacesDom {
  TextTrackCueListImpl.internal_() : super.internal_();
  get runtimeType => TextTrackCueList;
  toString() => super.toString();
}
@patch class TextTrackList {
  static Type get instanceRuntimeType => TextTrackListImpl;

}
class TextTrackListImpl extends TextTrackList implements js_library.JSObjectInterfacesDom {
  TextTrackListImpl.internal_() : super.internal_();
  get runtimeType => TextTrackList;
  toString() => super.toString();
}
@patch class TimeRanges {
  static Type get instanceRuntimeType => TimeRangesImpl;

}
class TimeRangesImpl extends TimeRanges implements js_library.JSObjectInterfacesDom {
  TimeRangesImpl.internal_() : super.internal_();
  get runtimeType => TimeRanges;
  toString() => super.toString();
}
@patch class TitleElement {
  static Type get instanceRuntimeType => TitleElementImpl;

}
class TitleElementImpl extends TitleElement implements js_library.JSObjectInterfacesDom {
  TitleElementImpl.internal_() : super.internal_();
  get runtimeType => TitleElement;
  toString() => super.toString();
}
@patch class Touch {
  static Type get instanceRuntimeType => TouchImpl;

}
class TouchImpl extends Touch implements js_library.JSObjectInterfacesDom {
  TouchImpl.internal_() : super.internal_();
  get runtimeType => Touch;
  toString() => super.toString();
}
@patch class TouchEvent {
  static Type get instanceRuntimeType => TouchEventImpl;

}
class TouchEventImpl extends TouchEvent implements js_library.JSObjectInterfacesDom {
  TouchEventImpl.internal_() : super.internal_();
  get runtimeType => TouchEvent;
  toString() => super.toString();
}
@patch class TouchList {
  static Type get instanceRuntimeType => TouchListImpl;

}
class TouchListImpl extends TouchList implements js_library.JSObjectInterfacesDom {
  TouchListImpl.internal_() : super.internal_();
  get runtimeType => TouchList;
  toString() => super.toString();
}
@patch class TrackDefault {
  static Type get instanceRuntimeType => TrackDefaultImpl;

}
class TrackDefaultImpl extends TrackDefault implements js_library.JSObjectInterfacesDom {
  TrackDefaultImpl.internal_() : super.internal_();
  get runtimeType => TrackDefault;
  toString() => super.toString();
}
@patch class TrackDefaultList {
  static Type get instanceRuntimeType => TrackDefaultListImpl;

}
class TrackDefaultListImpl extends TrackDefaultList implements js_library.JSObjectInterfacesDom {
  TrackDefaultListImpl.internal_() : super.internal_();
  get runtimeType => TrackDefaultList;
  toString() => super.toString();
}
@patch class TrackElement {
  static Type get instanceRuntimeType => TrackElementImpl;

}
class TrackElementImpl extends TrackElement implements js_library.JSObjectInterfacesDom {
  TrackElementImpl.internal_() : super.internal_();
  get runtimeType => TrackElement;
  toString() => super.toString();
}
@patch class TrackEvent {
  static Type get instanceRuntimeType => TrackEventImpl;

}
class TrackEventImpl extends TrackEvent implements js_library.JSObjectInterfacesDom {
  TrackEventImpl.internal_() : super.internal_();
  get runtimeType => TrackEvent;
  toString() => super.toString();
}
@patch class TransformComponent {
  static Type get instanceRuntimeType => TransformComponentImpl;

}
class TransformComponentImpl extends TransformComponent implements js_library.JSObjectInterfacesDom {
  TransformComponentImpl.internal_() : super.internal_();
  get runtimeType => TransformComponent;
  toString() => super.toString();
}
@patch class TransformValue {
  static Type get instanceRuntimeType => TransformValueImpl;

}
class TransformValueImpl extends TransformValue implements js_library.JSObjectInterfacesDom {
  TransformValueImpl.internal_() : super.internal_();
  get runtimeType => TransformValue;
  toString() => super.toString();
}
@patch class TransitionEvent {
  static Type get instanceRuntimeType => TransitionEventImpl;

}
class TransitionEventImpl extends TransitionEvent implements js_library.JSObjectInterfacesDom {
  TransitionEventImpl.internal_() : super.internal_();
  get runtimeType => TransitionEvent;
  toString() => super.toString();
}
@patch class Translation {
  static Type get instanceRuntimeType => TranslationImpl;

}
class TranslationImpl extends Translation implements js_library.JSObjectInterfacesDom {
  TranslationImpl.internal_() : super.internal_();
  get runtimeType => Translation;
  toString() => super.toString();
}
@patch class TreeWalker {
  static Type get instanceRuntimeType => TreeWalkerImpl;

}
class TreeWalkerImpl extends TreeWalker implements js_library.JSObjectInterfacesDom {
  TreeWalkerImpl.internal_() : super.internal_();
  get runtimeType => TreeWalker;
  toString() => super.toString();
}
@patch class UIEvent {
  static Type get instanceRuntimeType => UIEventImpl;

}
class UIEventImpl extends UIEvent implements js_library.JSObjectInterfacesDom {
  UIEventImpl.internal_() : super.internal_();
  get runtimeType => UIEvent;
  toString() => super.toString();
}
@patch class UListElement {
  static Type get instanceRuntimeType => UListElementImpl;

}
class UListElementImpl extends UListElement implements js_library.JSObjectInterfacesDom {
  UListElementImpl.internal_() : super.internal_();
  get runtimeType => UListElement;
  toString() => super.toString();
}
@patch class UnderlyingSourceBase {
  static Type get instanceRuntimeType => UnderlyingSourceBaseImpl;

}
class UnderlyingSourceBaseImpl extends UnderlyingSourceBase implements js_library.JSObjectInterfacesDom {
  UnderlyingSourceBaseImpl.internal_() : super.internal_();
  get runtimeType => UnderlyingSourceBase;
  toString() => super.toString();
}
@patch class UnknownElement {
  static Type get instanceRuntimeType => UnknownElementImpl;

}
class UnknownElementImpl extends UnknownElement implements js_library.JSObjectInterfacesDom {
  UnknownElementImpl.internal_() : super.internal_();
  get runtimeType => UnknownElement;
  toString() => super.toString();
}
@patch class Url {
  static Type get instanceRuntimeType => UrlImpl;

}
class UrlImpl extends Url implements js_library.JSObjectInterfacesDom {
  UrlImpl.internal_() : super.internal_();
  get runtimeType => Url;
  toString() => super.toString();
}
@patch class UrlSearchParams {
  static Type get instanceRuntimeType => UrlSearchParamsImpl;

}
class UrlSearchParamsImpl extends UrlSearchParams implements js_library.JSObjectInterfacesDom {
  UrlSearchParamsImpl.internal_() : super.internal_();
  get runtimeType => UrlSearchParams;
  toString() => super.toString();
}
@patch class UrlUtils {
  static Type get instanceRuntimeType => UrlUtilsImpl;

}
class UrlUtilsImpl extends UrlUtils implements js_library.JSObjectInterfacesDom {
  UrlUtilsImpl.internal_() : super.internal_();
  get runtimeType => UrlUtils;
  toString() => super.toString();
}
@patch class UrlUtilsReadOnly {
  static Type get instanceRuntimeType => UrlUtilsReadOnlyImpl;

}
class UrlUtilsReadOnlyImpl extends UrlUtilsReadOnly implements js_library.JSObjectInterfacesDom {
  UrlUtilsReadOnlyImpl.internal_() : super.internal_();
  get runtimeType => UrlUtilsReadOnly;
  toString() => super.toString();
}
@patch class VRDevice {
  static Type get instanceRuntimeType => VRDeviceImpl;

}
class VRDeviceImpl extends VRDevice implements js_library.JSObjectInterfacesDom {
  VRDeviceImpl.internal_() : super.internal_();
  get runtimeType => VRDevice;
  toString() => super.toString();
}
@patch class VREyeParameters {
  static Type get instanceRuntimeType => VREyeParametersImpl;

}
class VREyeParametersImpl extends VREyeParameters implements js_library.JSObjectInterfacesDom {
  VREyeParametersImpl.internal_() : super.internal_();
  get runtimeType => VREyeParameters;
  toString() => super.toString();
}
@patch class VRFieldOfView {
  static Type get instanceRuntimeType => VRFieldOfViewImpl;

}
class VRFieldOfViewImpl extends VRFieldOfView implements js_library.JSObjectInterfacesDom {
  VRFieldOfViewImpl.internal_() : super.internal_();
  get runtimeType => VRFieldOfView;
  toString() => super.toString();
}
@patch class VRPositionState {
  static Type get instanceRuntimeType => VRPositionStateImpl;

}
class VRPositionStateImpl extends VRPositionState implements js_library.JSObjectInterfacesDom {
  VRPositionStateImpl.internal_() : super.internal_();
  get runtimeType => VRPositionState;
  toString() => super.toString();
}
@patch class ValidityState {
  static Type get instanceRuntimeType => ValidityStateImpl;

}
class ValidityStateImpl extends ValidityState implements js_library.JSObjectInterfacesDom {
  ValidityStateImpl.internal_() : super.internal_();
  get runtimeType => ValidityState;
  toString() => super.toString();
}
@patch class VideoElement {
  static Type get instanceRuntimeType => VideoElementImpl;

}
class VideoElementImpl extends VideoElement implements js_library.JSObjectInterfacesDom {
  VideoElementImpl.internal_() : super.internal_();
  get runtimeType => VideoElement;
  toString() => super.toString();
}
@patch class VideoPlaybackQuality {
  static Type get instanceRuntimeType => VideoPlaybackQualityImpl;

}
class VideoPlaybackQualityImpl extends VideoPlaybackQuality implements js_library.JSObjectInterfacesDom {
  VideoPlaybackQualityImpl.internal_() : super.internal_();
  get runtimeType => VideoPlaybackQuality;
  toString() => super.toString();
}
@patch class VideoTrack {
  static Type get instanceRuntimeType => VideoTrackImpl;

}
class VideoTrackImpl extends VideoTrack implements js_library.JSObjectInterfacesDom {
  VideoTrackImpl.internal_() : super.internal_();
  get runtimeType => VideoTrack;
  toString() => super.toString();
}
@patch class VideoTrackList {
  static Type get instanceRuntimeType => VideoTrackListImpl;

}
class VideoTrackListImpl extends VideoTrackList implements js_library.JSObjectInterfacesDom {
  VideoTrackListImpl.internal_() : super.internal_();
  get runtimeType => VideoTrackList;
  toString() => super.toString();
}
@patch class VttCue {
  static Type get instanceRuntimeType => VttCueImpl;

}
class VttCueImpl extends VttCue implements js_library.JSObjectInterfacesDom {
  VttCueImpl.internal_() : super.internal_();
  get runtimeType => VttCue;
  toString() => super.toString();
}
@patch class VttRegion {
  static Type get instanceRuntimeType => VttRegionImpl;

}
class VttRegionImpl extends VttRegion implements js_library.JSObjectInterfacesDom {
  VttRegionImpl.internal_() : super.internal_();
  get runtimeType => VttRegion;
  toString() => super.toString();
}
@patch class VttRegionList {
  static Type get instanceRuntimeType => VttRegionListImpl;

}
class VttRegionListImpl extends VttRegionList implements js_library.JSObjectInterfacesDom {
  VttRegionListImpl.internal_() : super.internal_();
  get runtimeType => VttRegionList;
  toString() => super.toString();
}
@patch class WebSocket {
  static Type get instanceRuntimeType => WebSocketImpl;

}
class WebSocketImpl extends WebSocket implements js_library.JSObjectInterfacesDom {
  WebSocketImpl.internal_() : super.internal_();
  get runtimeType => WebSocket;
  toString() => super.toString();
}
@patch class WheelEvent {
  static Type get instanceRuntimeType => WheelEventImpl;

}
class WheelEventImpl extends WheelEvent implements js_library.JSObjectInterfacesDom {
  WheelEventImpl.internal_() : super.internal_();
  get runtimeType => WheelEvent;
  toString() => super.toString();
}
@patch class Window {
  static Type get instanceRuntimeType => WindowImpl;

}
class WindowImpl extends Window implements js_library.JSObjectInterfacesDom {
  WindowImpl.internal_() : super.internal_();
  get runtimeType => Window;
  toString() => super.toString();
}
@patch class WindowBase64 {
  static Type get instanceRuntimeType => WindowBase64Impl;

}
class WindowBase64Impl extends WindowBase64 implements js_library.JSObjectInterfacesDom {
  WindowBase64Impl.internal_() : super.internal_();
  get runtimeType => WindowBase64;
  toString() => super.toString();
}
@patch class WindowClient {
  static Type get instanceRuntimeType => WindowClientImpl;

}
class WindowClientImpl extends WindowClient implements js_library.JSObjectInterfacesDom {
  WindowClientImpl.internal_() : super.internal_();
  get runtimeType => WindowClient;
  toString() => super.toString();
}
@patch class WindowEventHandlers {
  static Type get instanceRuntimeType => WindowEventHandlersImpl;

}
class WindowEventHandlersImpl extends WindowEventHandlers implements js_library.JSObjectInterfacesDom {
  WindowEventHandlersImpl.internal_() : super.internal_();
  get runtimeType => WindowEventHandlers;
  toString() => super.toString();
}
@patch class Worker {
  static Type get instanceRuntimeType => WorkerImpl;

}
class WorkerImpl extends Worker implements js_library.JSObjectInterfacesDom {
  WorkerImpl.internal_() : super.internal_();
  get runtimeType => Worker;
  toString() => super.toString();
}
@patch class WorkerConsole {
  static Type get instanceRuntimeType => WorkerConsoleImpl;

}
class WorkerConsoleImpl extends WorkerConsole implements js_library.JSObjectInterfacesDom {
  WorkerConsoleImpl.internal_() : super.internal_();
  get runtimeType => WorkerConsole;
  toString() => super.toString();
}
@patch class WorkerGlobalScope {
  static Type get instanceRuntimeType => WorkerGlobalScopeImpl;

}
class WorkerGlobalScopeImpl extends WorkerGlobalScope implements js_library.JSObjectInterfacesDom {
  WorkerGlobalScopeImpl.internal_() : super.internal_();
  get runtimeType => WorkerGlobalScope;
  toString() => super.toString();
}
@patch class WorkerPerformance {
  static Type get instanceRuntimeType => WorkerPerformanceImpl;

}
class WorkerPerformanceImpl extends WorkerPerformance implements js_library.JSObjectInterfacesDom {
  WorkerPerformanceImpl.internal_() : super.internal_();
  get runtimeType => WorkerPerformance;
  toString() => super.toString();
}
@patch class XPathEvaluator {
  static Type get instanceRuntimeType => XPathEvaluatorImpl;

}
class XPathEvaluatorImpl extends XPathEvaluator implements js_library.JSObjectInterfacesDom {
  XPathEvaluatorImpl.internal_() : super.internal_();
  get runtimeType => XPathEvaluator;
  toString() => super.toString();
}
@patch class XPathExpression {
  static Type get instanceRuntimeType => XPathExpressionImpl;

}
class XPathExpressionImpl extends XPathExpression implements js_library.JSObjectInterfacesDom {
  XPathExpressionImpl.internal_() : super.internal_();
  get runtimeType => XPathExpression;
  toString() => super.toString();
}
@patch class XPathNSResolver {
  static Type get instanceRuntimeType => XPathNSResolverImpl;

}
class XPathNSResolverImpl extends XPathNSResolver implements js_library.JSObjectInterfacesDom {
  XPathNSResolverImpl.internal_() : super.internal_();
  get runtimeType => XPathNSResolver;
  toString() => super.toString();
}
@patch class XPathResult {
  static Type get instanceRuntimeType => XPathResultImpl;

}
class XPathResultImpl extends XPathResult implements js_library.JSObjectInterfacesDom {
  XPathResultImpl.internal_() : super.internal_();
  get runtimeType => XPathResult;
  toString() => super.toString();
}
@patch class XmlDocument {
  static Type get instanceRuntimeType => XmlDocumentImpl;

}
class XmlDocumentImpl extends XmlDocument implements js_library.JSObjectInterfacesDom {
  XmlDocumentImpl.internal_() : super.internal_();
  get runtimeType => XmlDocument;
  toString() => super.toString();
}
@patch class XmlSerializer {
  static Type get instanceRuntimeType => XmlSerializerImpl;

}
class XmlSerializerImpl extends XmlSerializer implements js_library.JSObjectInterfacesDom {
  XmlSerializerImpl.internal_() : super.internal_();
  get runtimeType => XmlSerializer;
  toString() => super.toString();
}
@patch class XsltProcessor {
  static Type get instanceRuntimeType => XsltProcessorImpl;

}
class XsltProcessorImpl extends XsltProcessor implements js_library.JSObjectInterfacesDom {
  XsltProcessorImpl.internal_() : super.internal_();
  get runtimeType => XsltProcessor;
  toString() => super.toString();
}
@patch class _Attr {
  static Type get instanceRuntimeType => _AttrImpl;

}
class _AttrImpl extends _Attr implements js_library.JSObjectInterfacesDom {
  _AttrImpl.internal_() : super.internal_();
  get runtimeType => _Attr;
  toString() => super.toString();
}
@patch class _Bluetooth {
  static Type get instanceRuntimeType => _BluetoothImpl;

}
class _BluetoothImpl extends _Bluetooth implements js_library.JSObjectInterfacesDom {
  _BluetoothImpl.internal_() : super.internal_();
  get runtimeType => _Bluetooth;
  toString() => super.toString();
}
@patch class _BluetoothAdvertisingData {
  static Type get instanceRuntimeType => _BluetoothAdvertisingDataImpl;

}
class _BluetoothAdvertisingDataImpl extends _BluetoothAdvertisingData implements js_library.JSObjectInterfacesDom {
  _BluetoothAdvertisingDataImpl.internal_() : super.internal_();
  get runtimeType => _BluetoothAdvertisingData;
  toString() => super.toString();
}
@patch class _BluetoothCharacteristicProperties {
  static Type get instanceRuntimeType => _BluetoothCharacteristicPropertiesImpl;

}
class _BluetoothCharacteristicPropertiesImpl extends _BluetoothCharacteristicProperties implements js_library.JSObjectInterfacesDom {
  _BluetoothCharacteristicPropertiesImpl.internal_() : super.internal_();
  get runtimeType => _BluetoothCharacteristicProperties;
  toString() => super.toString();
}
@patch class _BluetoothDevice {
  static Type get instanceRuntimeType => _BluetoothDeviceImpl;

}
class _BluetoothDeviceImpl extends _BluetoothDevice implements js_library.JSObjectInterfacesDom {
  _BluetoothDeviceImpl.internal_() : super.internal_();
  get runtimeType => _BluetoothDevice;
  toString() => super.toString();
}
@patch class _BluetoothRemoteGATTCharacteristic {
  static Type get instanceRuntimeType => _BluetoothRemoteGATTCharacteristicImpl;

}
class _BluetoothRemoteGATTCharacteristicImpl extends _BluetoothRemoteGATTCharacteristic implements js_library.JSObjectInterfacesDom {
  _BluetoothRemoteGATTCharacteristicImpl.internal_() : super.internal_();
  get runtimeType => _BluetoothRemoteGATTCharacteristic;
  toString() => super.toString();
}
@patch class _BluetoothRemoteGATTServer {
  static Type get instanceRuntimeType => _BluetoothRemoteGATTServerImpl;

}
class _BluetoothRemoteGATTServerImpl extends _BluetoothRemoteGATTServer implements js_library.JSObjectInterfacesDom {
  _BluetoothRemoteGATTServerImpl.internal_() : super.internal_();
  get runtimeType => _BluetoothRemoteGATTServer;
  toString() => super.toString();
}
@patch class _BluetoothRemoteGATTService {
  static Type get instanceRuntimeType => _BluetoothRemoteGATTServiceImpl;

}
class _BluetoothRemoteGATTServiceImpl extends _BluetoothRemoteGATTService implements js_library.JSObjectInterfacesDom {
  _BluetoothRemoteGATTServiceImpl.internal_() : super.internal_();
  get runtimeType => _BluetoothRemoteGATTService;
  toString() => super.toString();
}
@patch class _BluetoothUUID {
  static Type get instanceRuntimeType => _BluetoothUUIDImpl;

}
class _BluetoothUUIDImpl extends _BluetoothUUID implements js_library.JSObjectInterfacesDom {
  _BluetoothUUIDImpl.internal_() : super.internal_();
  get runtimeType => _BluetoothUUID;
  toString() => super.toString();
}
@patch class _Cache {
  static Type get instanceRuntimeType => _CacheImpl;

}
class _CacheImpl extends _Cache implements js_library.JSObjectInterfacesDom {
  _CacheImpl.internal_() : super.internal_();
  get runtimeType => _Cache;
  toString() => super.toString();
}
@patch class _CanvasPathMethods {
  static Type get instanceRuntimeType => _CanvasPathMethodsImpl;

}
class _CanvasPathMethodsImpl extends _CanvasPathMethods implements js_library.JSObjectInterfacesDom {
  _CanvasPathMethodsImpl.internal_() : super.internal_();
  get runtimeType => _CanvasPathMethods;
  toString() => super.toString();
}
@patch class _ClientRect {
  static Type get instanceRuntimeType => _ClientRectImpl;

}
class _ClientRectImpl extends _ClientRect implements js_library.JSObjectInterfacesDom {
  _ClientRectImpl.internal_() : super.internal_();
  get runtimeType => _ClientRect;
  toString() => super.toString();
}
@patch class _ClientRectList {
  static Type get instanceRuntimeType => _ClientRectListImpl;

}
class _ClientRectListImpl extends _ClientRectList implements js_library.JSObjectInterfacesDom {
  _ClientRectListImpl.internal_() : super.internal_();
  get runtimeType => _ClientRectList;
  toString() => super.toString();
}
@patch class _CssRuleList {
  static Type get instanceRuntimeType => _CssRuleListImpl;

}
class _CssRuleListImpl extends _CssRuleList implements js_library.JSObjectInterfacesDom {
  _CssRuleListImpl.internal_() : super.internal_();
  get runtimeType => _CssRuleList;
  toString() => super.toString();
}
@patch class _DOMFileSystemSync {
  static Type get instanceRuntimeType => _DOMFileSystemSyncImpl;

}
class _DOMFileSystemSyncImpl extends _DOMFileSystemSync implements js_library.JSObjectInterfacesDom {
  _DOMFileSystemSyncImpl.internal_() : super.internal_();
  get runtimeType => _DOMFileSystemSync;
  toString() => super.toString();
}
@patch class _DirectoryEntrySync {
  static Type get instanceRuntimeType => _DirectoryEntrySyncImpl;

}
class _DirectoryEntrySyncImpl extends _DirectoryEntrySync implements js_library.JSObjectInterfacesDom {
  _DirectoryEntrySyncImpl.internal_() : super.internal_();
  get runtimeType => _DirectoryEntrySync;
  toString() => super.toString();
}
@patch class _DirectoryReaderSync {
  static Type get instanceRuntimeType => _DirectoryReaderSyncImpl;

}
class _DirectoryReaderSyncImpl extends _DirectoryReaderSync implements js_library.JSObjectInterfacesDom {
  _DirectoryReaderSyncImpl.internal_() : super.internal_();
  get runtimeType => _DirectoryReaderSync;
  toString() => super.toString();
}
@patch class _DocumentType {
  static Type get instanceRuntimeType => _DocumentTypeImpl;

}
class _DocumentTypeImpl extends _DocumentType implements js_library.JSObjectInterfacesDom {
  _DocumentTypeImpl.internal_() : super.internal_();
  get runtimeType => _DocumentType;
  toString() => super.toString();
}
@patch class _DomRect {
  static Type get instanceRuntimeType => _DomRectImpl;

}
class _DomRectImpl extends _DomRect implements js_library.JSObjectInterfacesDom {
  _DomRectImpl.internal_() : super.internal_();
  get runtimeType => _DomRect;
  toString() => super.toString();
}
@patch class _EntrySync {
  static Type get instanceRuntimeType => _EntrySyncImpl;

}
class _EntrySyncImpl extends _EntrySync implements js_library.JSObjectInterfacesDom {
  _EntrySyncImpl.internal_() : super.internal_();
  get runtimeType => _EntrySync;
  toString() => super.toString();
}
@patch class _FileEntrySync {
  static Type get instanceRuntimeType => _FileEntrySyncImpl;

}
class _FileEntrySyncImpl extends _FileEntrySync implements js_library.JSObjectInterfacesDom {
  _FileEntrySyncImpl.internal_() : super.internal_();
  get runtimeType => _FileEntrySync;
  toString() => super.toString();
}
@patch class _FileReaderSync {
  static Type get instanceRuntimeType => _FileReaderSyncImpl;

}
class _FileReaderSyncImpl extends _FileReaderSync implements js_library.JSObjectInterfacesDom {
  _FileReaderSyncImpl.internal_() : super.internal_();
  get runtimeType => _FileReaderSync;
  toString() => super.toString();
}
@patch class _FileWriterSync {
  static Type get instanceRuntimeType => _FileWriterSyncImpl;

}
class _FileWriterSyncImpl extends _FileWriterSync implements js_library.JSObjectInterfacesDom {
  _FileWriterSyncImpl.internal_() : super.internal_();
  get runtimeType => _FileWriterSync;
  toString() => super.toString();
}
@patch class _GamepadList {
  static Type get instanceRuntimeType => _GamepadListImpl;

}
class _GamepadListImpl extends _GamepadList implements js_library.JSObjectInterfacesDom {
  _GamepadListImpl.internal_() : super.internal_();
  get runtimeType => _GamepadList;
  toString() => super.toString();
}
@patch class _HTMLAllCollection {
  static Type get instanceRuntimeType => _HTMLAllCollectionImpl;

}
class _HTMLAllCollectionImpl extends _HTMLAllCollection implements js_library.JSObjectInterfacesDom {
  _HTMLAllCollectionImpl.internal_() : super.internal_();
  get runtimeType => _HTMLAllCollection;
  toString() => super.toString();
}
@patch class _HTMLDirectoryElement {
  static Type get instanceRuntimeType => _HTMLDirectoryElementImpl;

}
class _HTMLDirectoryElementImpl extends _HTMLDirectoryElement implements js_library.JSObjectInterfacesDom {
  _HTMLDirectoryElementImpl.internal_() : super.internal_();
  get runtimeType => _HTMLDirectoryElement;
  toString() => super.toString();
}
@patch class _HTMLFontElement {
  static Type get instanceRuntimeType => _HTMLFontElementImpl;

}
class _HTMLFontElementImpl extends _HTMLFontElement implements js_library.JSObjectInterfacesDom {
  _HTMLFontElementImpl.internal_() : super.internal_();
  get runtimeType => _HTMLFontElement;
  toString() => super.toString();
}
@patch class _HTMLFrameElement {
  static Type get instanceRuntimeType => _HTMLFrameElementImpl;

}
class _HTMLFrameElementImpl extends _HTMLFrameElement implements js_library.JSObjectInterfacesDom {
  _HTMLFrameElementImpl.internal_() : super.internal_();
  get runtimeType => _HTMLFrameElement;
  toString() => super.toString();
}
@patch class _HTMLFrameSetElement {
  static Type get instanceRuntimeType => _HTMLFrameSetElementImpl;

}
class _HTMLFrameSetElementImpl extends _HTMLFrameSetElement implements js_library.JSObjectInterfacesDom {
  _HTMLFrameSetElementImpl.internal_() : super.internal_();
  get runtimeType => _HTMLFrameSetElement;
  toString() => super.toString();
}
@patch class _HTMLMarqueeElement {
  static Type get instanceRuntimeType => _HTMLMarqueeElementImpl;

}
class _HTMLMarqueeElementImpl extends _HTMLMarqueeElement implements js_library.JSObjectInterfacesDom {
  _HTMLMarqueeElementImpl.internal_() : super.internal_();
  get runtimeType => _HTMLMarqueeElement;
  toString() => super.toString();
}
@patch class _NFC {
  static Type get instanceRuntimeType => _NFCImpl;

}
class _NFCImpl extends _NFC implements js_library.JSObjectInterfacesDom {
  _NFCImpl.internal_() : super.internal_();
  get runtimeType => _NFC;
  toString() => super.toString();
}
@patch class _NamedNodeMap {
  static Type get instanceRuntimeType => _NamedNodeMapImpl;

}
class _NamedNodeMapImpl extends _NamedNodeMap implements js_library.JSObjectInterfacesDom {
  _NamedNodeMapImpl.internal_() : super.internal_();
  get runtimeType => _NamedNodeMap;
  toString() => super.toString();
}
@patch class _PagePopupController {
  static Type get instanceRuntimeType => _PagePopupControllerImpl;

}
class _PagePopupControllerImpl extends _PagePopupController implements js_library.JSObjectInterfacesDom {
  _PagePopupControllerImpl.internal_() : super.internal_();
  get runtimeType => _PagePopupController;
  toString() => super.toString();
}
@patch class _RadioNodeList {
  static Type get instanceRuntimeType => _RadioNodeListImpl;

}
class _RadioNodeListImpl extends _RadioNodeList implements js_library.JSObjectInterfacesDom {
  _RadioNodeListImpl.internal_() : super.internal_();
  get runtimeType => _RadioNodeList;
  toString() => super.toString();
}
@patch class _Request {
  static Type get instanceRuntimeType => _RequestImpl;

}
class _RequestImpl extends _Request implements js_library.JSObjectInterfacesDom {
  _RequestImpl.internal_() : super.internal_();
  get runtimeType => _Request;
  toString() => super.toString();
}
@patch class _ResourceProgressEvent {
  static Type get instanceRuntimeType => _ResourceProgressEventImpl;

}
class _ResourceProgressEventImpl extends _ResourceProgressEvent implements js_library.JSObjectInterfacesDom {
  _ResourceProgressEventImpl.internal_() : super.internal_();
  get runtimeType => _ResourceProgressEvent;
  toString() => super.toString();
}
@patch class _Response {
  static Type get instanceRuntimeType => _ResponseImpl;

}
class _ResponseImpl extends _Response implements js_library.JSObjectInterfacesDom {
  _ResponseImpl.internal_() : super.internal_();
  get runtimeType => _Response;
  toString() => super.toString();
}
@patch class _ServiceWorker {
  static Type get instanceRuntimeType => _ServiceWorkerImpl;

}
class _ServiceWorkerImpl extends _ServiceWorker implements js_library.JSObjectInterfacesDom {
  _ServiceWorkerImpl.internal_() : super.internal_();
  get runtimeType => _ServiceWorker;
  toString() => super.toString();
}
@patch class _SpeechRecognitionResultList {
  static Type get instanceRuntimeType => _SpeechRecognitionResultListImpl;

}
class _SpeechRecognitionResultListImpl extends _SpeechRecognitionResultList implements js_library.JSObjectInterfacesDom {
  _SpeechRecognitionResultListImpl.internal_() : super.internal_();
  get runtimeType => _SpeechRecognitionResultList;
  toString() => super.toString();
}
@patch class _StyleSheetList {
  static Type get instanceRuntimeType => _StyleSheetListImpl;

}
class _StyleSheetListImpl extends _StyleSheetList implements js_library.JSObjectInterfacesDom {
  _StyleSheetListImpl.internal_() : super.internal_();
  get runtimeType => _StyleSheetList;
  toString() => super.toString();
}
@patch class _SubtleCrypto {
  static Type get instanceRuntimeType => _SubtleCryptoImpl;

}
class _SubtleCryptoImpl extends _SubtleCrypto implements js_library.JSObjectInterfacesDom {
  _SubtleCryptoImpl.internal_() : super.internal_();
  get runtimeType => _SubtleCrypto;
  toString() => super.toString();
}
@patch class _USB {
  static Type get instanceRuntimeType => _USBImpl;

}
class _USBImpl extends _USB implements js_library.JSObjectInterfacesDom {
  _USBImpl.internal_() : super.internal_();
  get runtimeType => _USB;
  toString() => super.toString();
}
@patch class _USBAlternateInterface {
  static Type get instanceRuntimeType => _USBAlternateInterfaceImpl;

}
class _USBAlternateInterfaceImpl extends _USBAlternateInterface implements js_library.JSObjectInterfacesDom {
  _USBAlternateInterfaceImpl.internal_() : super.internal_();
  get runtimeType => _USBAlternateInterface;
  toString() => super.toString();
}
@patch class _USBConfiguration {
  static Type get instanceRuntimeType => _USBConfigurationImpl;

}
class _USBConfigurationImpl extends _USBConfiguration implements js_library.JSObjectInterfacesDom {
  _USBConfigurationImpl.internal_() : super.internal_();
  get runtimeType => _USBConfiguration;
  toString() => super.toString();
}
@patch class _USBConnectionEvent {
  static Type get instanceRuntimeType => _USBConnectionEventImpl;

}
class _USBConnectionEventImpl extends _USBConnectionEvent implements js_library.JSObjectInterfacesDom {
  _USBConnectionEventImpl.internal_() : super.internal_();
  get runtimeType => _USBConnectionEvent;
  toString() => super.toString();
}
@patch class _USBDevice {
  static Type get instanceRuntimeType => _USBDeviceImpl;

}
class _USBDeviceImpl extends _USBDevice implements js_library.JSObjectInterfacesDom {
  _USBDeviceImpl.internal_() : super.internal_();
  get runtimeType => _USBDevice;
  toString() => super.toString();
}
@patch class _USBEndpoint {
  static Type get instanceRuntimeType => _USBEndpointImpl;

}
class _USBEndpointImpl extends _USBEndpoint implements js_library.JSObjectInterfacesDom {
  _USBEndpointImpl.internal_() : super.internal_();
  get runtimeType => _USBEndpoint;
  toString() => super.toString();
}
@patch class _USBInTransferResult {
  static Type get instanceRuntimeType => _USBInTransferResultImpl;

}
class _USBInTransferResultImpl extends _USBInTransferResult implements js_library.JSObjectInterfacesDom {
  _USBInTransferResultImpl.internal_() : super.internal_();
  get runtimeType => _USBInTransferResult;
  toString() => super.toString();
}
@patch class _USBInterface {
  static Type get instanceRuntimeType => _USBInterfaceImpl;

}
class _USBInterfaceImpl extends _USBInterface implements js_library.JSObjectInterfacesDom {
  _USBInterfaceImpl.internal_() : super.internal_();
  get runtimeType => _USBInterface;
  toString() => super.toString();
}
@patch class _USBIsochronousInTransferPacket {
  static Type get instanceRuntimeType => _USBIsochronousInTransferPacketImpl;

}
class _USBIsochronousInTransferPacketImpl extends _USBIsochronousInTransferPacket implements js_library.JSObjectInterfacesDom {
  _USBIsochronousInTransferPacketImpl.internal_() : super.internal_();
  get runtimeType => _USBIsochronousInTransferPacket;
  toString() => super.toString();
}
@patch class _USBIsochronousInTransferResult {
  static Type get instanceRuntimeType => _USBIsochronousInTransferResultImpl;

}
class _USBIsochronousInTransferResultImpl extends _USBIsochronousInTransferResult implements js_library.JSObjectInterfacesDom {
  _USBIsochronousInTransferResultImpl.internal_() : super.internal_();
  get runtimeType => _USBIsochronousInTransferResult;
  toString() => super.toString();
}
@patch class _USBIsochronousOutTransferPacket {
  static Type get instanceRuntimeType => _USBIsochronousOutTransferPacketImpl;

}
class _USBIsochronousOutTransferPacketImpl extends _USBIsochronousOutTransferPacket implements js_library.JSObjectInterfacesDom {
  _USBIsochronousOutTransferPacketImpl.internal_() : super.internal_();
  get runtimeType => _USBIsochronousOutTransferPacket;
  toString() => super.toString();
}
@patch class _USBIsochronousOutTransferResult {
  static Type get instanceRuntimeType => _USBIsochronousOutTransferResultImpl;

}
class _USBIsochronousOutTransferResultImpl extends _USBIsochronousOutTransferResult implements js_library.JSObjectInterfacesDom {
  _USBIsochronousOutTransferResultImpl.internal_() : super.internal_();
  get runtimeType => _USBIsochronousOutTransferResult;
  toString() => super.toString();
}
@patch class _USBOutTransferResult {
  static Type get instanceRuntimeType => _USBOutTransferResultImpl;

}
class _USBOutTransferResultImpl extends _USBOutTransferResult implements js_library.JSObjectInterfacesDom {
  _USBOutTransferResultImpl.internal_() : super.internal_();
  get runtimeType => _USBOutTransferResult;
  toString() => super.toString();
}
@patch class _WebKitCSSMatrix {
  static Type get instanceRuntimeType => _WebKitCSSMatrixImpl;

}
class _WebKitCSSMatrixImpl extends _WebKitCSSMatrix implements js_library.JSObjectInterfacesDom {
  _WebKitCSSMatrixImpl.internal_() : super.internal_();
  get runtimeType => _WebKitCSSMatrix;
  toString() => super.toString();
}
@patch class _WindowTimers {
  static Type get instanceRuntimeType => _WindowTimersImpl;

}
class _WindowTimersImpl extends _WindowTimers implements js_library.JSObjectInterfacesDom {
  _WindowTimersImpl.internal_() : super.internal_();
  get runtimeType => _WindowTimers;
  toString() => super.toString();
}
@patch class _WorkerLocation {
  static Type get instanceRuntimeType => _WorkerLocationImpl;

}
class _WorkerLocationImpl extends _WorkerLocation implements js_library.JSObjectInterfacesDom {
  _WorkerLocationImpl.internal_() : super.internal_();
  get runtimeType => _WorkerLocation;
  toString() => super.toString();
}
@patch class _WorkerNavigator {
  static Type get instanceRuntimeType => _WorkerNavigatorImpl;

}
class _WorkerNavigatorImpl extends _WorkerNavigator implements js_library.JSObjectInterfacesDom {
  _WorkerNavigatorImpl.internal_() : super.internal_();
  get runtimeType => _WorkerNavigator;
  toString() => super.toString();
}
@patch class _Worklet {
  static Type get instanceRuntimeType => _WorkletImpl;

}
class _WorkletImpl extends _Worklet implements js_library.JSObjectInterfacesDom {
  _WorkletImpl.internal_() : super.internal_();
  get runtimeType => _Worklet;
  toString() => super.toString();
}
@patch class _WorkletGlobalScope {
  static Type get instanceRuntimeType => _WorkletGlobalScopeImpl;

}
class _WorkletGlobalScopeImpl extends _WorkletGlobalScope implements js_library.JSObjectInterfacesDom {
  _WorkletGlobalScopeImpl.internal_() : super.internal_();
  get runtimeType => _WorkletGlobalScope;
  toString() => super.toString();
}

"""
  ],
  "dart:indexed_db": [
    "dart:indexed_db",
    "dart:indexed_db_js_interop_patch.dart",
    """import 'dart:js' as js_library;

/**
 * Placeholder object for cases where we need to determine exactly how many
 * args were passed to a function.
 */
const _UNDEFINED_JS_CONST = const Object();

@patch class Cursor {
  static Type get instanceRuntimeType => CursorImpl;

}
class CursorImpl extends Cursor implements js_library.JSObjectInterfacesDom {
  CursorImpl.internal_() : super.internal_();
  get runtimeType => Cursor;
  toString() => super.toString();
}
@patch class CursorWithValue {
  static Type get instanceRuntimeType => CursorWithValueImpl;

}
class CursorWithValueImpl extends CursorWithValue implements js_library.JSObjectInterfacesDom {
  CursorWithValueImpl.internal_() : super.internal_();
  get runtimeType => CursorWithValue;
  toString() => super.toString();
}
@patch class Database {
  static Type get instanceRuntimeType => DatabaseImpl;

}
class DatabaseImpl extends Database implements js_library.JSObjectInterfacesDom {
  DatabaseImpl.internal_() : super.internal_();
  get runtimeType => Database;
  toString() => super.toString();
}
@patch class IdbFactory {
  static Type get instanceRuntimeType => IdbFactoryImpl;

}
class IdbFactoryImpl extends IdbFactory implements js_library.JSObjectInterfacesDom {
  IdbFactoryImpl.internal_() : super.internal_();
  get runtimeType => IdbFactory;
  toString() => super.toString();
}
@patch class Index {
  static Type get instanceRuntimeType => IndexImpl;

}
class IndexImpl extends Index implements js_library.JSObjectInterfacesDom {
  IndexImpl.internal_() : super.internal_();
  get runtimeType => Index;
  toString() => super.toString();
}
@patch class KeyRange {
  static Type get instanceRuntimeType => KeyRangeImpl;

}
class KeyRangeImpl extends KeyRange implements js_library.JSObjectInterfacesDom {
  KeyRangeImpl.internal_() : super.internal_();
  get runtimeType => KeyRange;
  toString() => super.toString();
}
@patch class ObjectStore {
  static Type get instanceRuntimeType => ObjectStoreImpl;

}
class ObjectStoreImpl extends ObjectStore implements js_library.JSObjectInterfacesDom {
  ObjectStoreImpl.internal_() : super.internal_();
  get runtimeType => ObjectStore;
  toString() => super.toString();
}
@patch class OpenDBRequest {
  static Type get instanceRuntimeType => OpenDBRequestImpl;

}
class OpenDBRequestImpl extends OpenDBRequest implements js_library.JSObjectInterfacesDom {
  OpenDBRequestImpl.internal_() : super.internal_();
  get runtimeType => OpenDBRequest;
  toString() => super.toString();
}
@patch class Request {
  static Type get instanceRuntimeType => RequestImpl;

}
class RequestImpl extends Request implements js_library.JSObjectInterfacesDom {
  RequestImpl.internal_() : super.internal_();
  get runtimeType => Request;
  toString() => super.toString();
}
@patch class Transaction {
  static Type get instanceRuntimeType => TransactionImpl;

}
class TransactionImpl extends Transaction implements js_library.JSObjectInterfacesDom {
  TransactionImpl.internal_() : super.internal_();
  get runtimeType => Transaction;
  toString() => super.toString();
}
@patch class VersionChangeEvent {
  static Type get instanceRuntimeType => VersionChangeEventImpl;

}
class VersionChangeEventImpl extends VersionChangeEvent implements js_library.JSObjectInterfacesDom {
  VersionChangeEventImpl.internal_() : super.internal_();
  get runtimeType => VersionChangeEvent;
  toString() => super.toString();
}

"""
  ],
  "dart:web_gl": [
    "dart:web_gl",
    "dart:web_gl_js_interop_patch.dart",
    """import 'dart:js' as js_library;

/**
 * Placeholder object for cases where we need to determine exactly how many
 * args were passed to a function.
 */
const _UNDEFINED_JS_CONST = const Object();

@patch class ActiveInfo {
  static Type get instanceRuntimeType => ActiveInfoImpl;

}
class ActiveInfoImpl extends ActiveInfo implements js_library.JSObjectInterfacesDom {
  ActiveInfoImpl.internal_() : super.internal_();
  get runtimeType => ActiveInfo;
  toString() => super.toString();
}
@patch class AngleInstancedArrays {
  static Type get instanceRuntimeType => AngleInstancedArraysImpl;

}
class AngleInstancedArraysImpl extends AngleInstancedArrays implements js_library.JSObjectInterfacesDom {
  AngleInstancedArraysImpl.internal_() : super.internal_();
  get runtimeType => AngleInstancedArrays;
  toString() => super.toString();
}
@patch class Buffer {
  static Type get instanceRuntimeType => BufferImpl;

}
class BufferImpl extends Buffer implements js_library.JSObjectInterfacesDom {
  BufferImpl.internal_() : super.internal_();
  get runtimeType => Buffer;
  toString() => super.toString();
}
@patch class ChromiumSubscribeUniform {
  static Type get instanceRuntimeType => ChromiumSubscribeUniformImpl;

}
class ChromiumSubscribeUniformImpl extends ChromiumSubscribeUniform implements js_library.JSObjectInterfacesDom {
  ChromiumSubscribeUniformImpl.internal_() : super.internal_();
  get runtimeType => ChromiumSubscribeUniform;
  toString() => super.toString();
}
@patch class CompressedTextureAstc {
  static Type get instanceRuntimeType => CompressedTextureAstcImpl;

}
class CompressedTextureAstcImpl extends CompressedTextureAstc implements js_library.JSObjectInterfacesDom {
  CompressedTextureAstcImpl.internal_() : super.internal_();
  get runtimeType => CompressedTextureAstc;
  toString() => super.toString();
}
@patch class CompressedTextureAtc {
  static Type get instanceRuntimeType => CompressedTextureAtcImpl;

}
class CompressedTextureAtcImpl extends CompressedTextureAtc implements js_library.JSObjectInterfacesDom {
  CompressedTextureAtcImpl.internal_() : super.internal_();
  get runtimeType => CompressedTextureAtc;
  toString() => super.toString();
}
@patch class CompressedTextureETC1 {
  static Type get instanceRuntimeType => CompressedTextureETC1Impl;

}
class CompressedTextureETC1Impl extends CompressedTextureETC1 implements js_library.JSObjectInterfacesDom {
  CompressedTextureETC1Impl.internal_() : super.internal_();
  get runtimeType => CompressedTextureETC1;
  toString() => super.toString();
}
@patch class CompressedTexturePvrtc {
  static Type get instanceRuntimeType => CompressedTexturePvrtcImpl;

}
class CompressedTexturePvrtcImpl extends CompressedTexturePvrtc implements js_library.JSObjectInterfacesDom {
  CompressedTexturePvrtcImpl.internal_() : super.internal_();
  get runtimeType => CompressedTexturePvrtc;
  toString() => super.toString();
}
@patch class CompressedTextureS3TC {
  static Type get instanceRuntimeType => CompressedTextureS3TCImpl;

}
class CompressedTextureS3TCImpl extends CompressedTextureS3TC implements js_library.JSObjectInterfacesDom {
  CompressedTextureS3TCImpl.internal_() : super.internal_();
  get runtimeType => CompressedTextureS3TC;
  toString() => super.toString();
}
@patch class ContextEvent {
  static Type get instanceRuntimeType => ContextEventImpl;

}
class ContextEventImpl extends ContextEvent implements js_library.JSObjectInterfacesDom {
  ContextEventImpl.internal_() : super.internal_();
  get runtimeType => ContextEvent;
  toString() => super.toString();
}
@patch class DebugRendererInfo {
  static Type get instanceRuntimeType => DebugRendererInfoImpl;

}
class DebugRendererInfoImpl extends DebugRendererInfo implements js_library.JSObjectInterfacesDom {
  DebugRendererInfoImpl.internal_() : super.internal_();
  get runtimeType => DebugRendererInfo;
  toString() => super.toString();
}
@patch class DebugShaders {
  static Type get instanceRuntimeType => DebugShadersImpl;

}
class DebugShadersImpl extends DebugShaders implements js_library.JSObjectInterfacesDom {
  DebugShadersImpl.internal_() : super.internal_();
  get runtimeType => DebugShaders;
  toString() => super.toString();
}
@patch class DepthTexture {
  static Type get instanceRuntimeType => DepthTextureImpl;

}
class DepthTextureImpl extends DepthTexture implements js_library.JSObjectInterfacesDom {
  DepthTextureImpl.internal_() : super.internal_();
  get runtimeType => DepthTexture;
  toString() => super.toString();
}
@patch class DrawBuffers {
  static Type get instanceRuntimeType => DrawBuffersImpl;

}
class DrawBuffersImpl extends DrawBuffers implements js_library.JSObjectInterfacesDom {
  DrawBuffersImpl.internal_() : super.internal_();
  get runtimeType => DrawBuffers;
  toString() => super.toString();
}
@patch class EXTsRgb {
  static Type get instanceRuntimeType => EXTsRgbImpl;

}
class EXTsRgbImpl extends EXTsRgb implements js_library.JSObjectInterfacesDom {
  EXTsRgbImpl.internal_() : super.internal_();
  get runtimeType => EXTsRgb;
  toString() => super.toString();
}
@patch class ExtBlendMinMax {
  static Type get instanceRuntimeType => ExtBlendMinMaxImpl;

}
class ExtBlendMinMaxImpl extends ExtBlendMinMax implements js_library.JSObjectInterfacesDom {
  ExtBlendMinMaxImpl.internal_() : super.internal_();
  get runtimeType => ExtBlendMinMax;
  toString() => super.toString();
}
@patch class ExtColorBufferFloat {
  static Type get instanceRuntimeType => ExtColorBufferFloatImpl;

}
class ExtColorBufferFloatImpl extends ExtColorBufferFloat implements js_library.JSObjectInterfacesDom {
  ExtColorBufferFloatImpl.internal_() : super.internal_();
  get runtimeType => ExtColorBufferFloat;
  toString() => super.toString();
}
@patch class ExtDisjointTimerQuery {
  static Type get instanceRuntimeType => ExtDisjointTimerQueryImpl;

}
class ExtDisjointTimerQueryImpl extends ExtDisjointTimerQuery implements js_library.JSObjectInterfacesDom {
  ExtDisjointTimerQueryImpl.internal_() : super.internal_();
  get runtimeType => ExtDisjointTimerQuery;
  toString() => super.toString();
}
@patch class ExtFragDepth {
  static Type get instanceRuntimeType => ExtFragDepthImpl;

}
class ExtFragDepthImpl extends ExtFragDepth implements js_library.JSObjectInterfacesDom {
  ExtFragDepthImpl.internal_() : super.internal_();
  get runtimeType => ExtFragDepth;
  toString() => super.toString();
}
@patch class ExtShaderTextureLod {
  static Type get instanceRuntimeType => ExtShaderTextureLodImpl;

}
class ExtShaderTextureLodImpl extends ExtShaderTextureLod implements js_library.JSObjectInterfacesDom {
  ExtShaderTextureLodImpl.internal_() : super.internal_();
  get runtimeType => ExtShaderTextureLod;
  toString() => super.toString();
}
@patch class ExtTextureFilterAnisotropic {
  static Type get instanceRuntimeType => ExtTextureFilterAnisotropicImpl;

}
class ExtTextureFilterAnisotropicImpl extends ExtTextureFilterAnisotropic implements js_library.JSObjectInterfacesDom {
  ExtTextureFilterAnisotropicImpl.internal_() : super.internal_();
  get runtimeType => ExtTextureFilterAnisotropic;
  toString() => super.toString();
}
@patch class Framebuffer {
  static Type get instanceRuntimeType => FramebufferImpl;

}
class FramebufferImpl extends Framebuffer implements js_library.JSObjectInterfacesDom {
  FramebufferImpl.internal_() : super.internal_();
  get runtimeType => Framebuffer;
  toString() => super.toString();
}
@patch class LoseContext {
  static Type get instanceRuntimeType => LoseContextImpl;

}
class LoseContextImpl extends LoseContext implements js_library.JSObjectInterfacesDom {
  LoseContextImpl.internal_() : super.internal_();
  get runtimeType => LoseContext;
  toString() => super.toString();
}
@patch class OesElementIndexUint {
  static Type get instanceRuntimeType => OesElementIndexUintImpl;

}
class OesElementIndexUintImpl extends OesElementIndexUint implements js_library.JSObjectInterfacesDom {
  OesElementIndexUintImpl.internal_() : super.internal_();
  get runtimeType => OesElementIndexUint;
  toString() => super.toString();
}
@patch class OesStandardDerivatives {
  static Type get instanceRuntimeType => OesStandardDerivativesImpl;

}
class OesStandardDerivativesImpl extends OesStandardDerivatives implements js_library.JSObjectInterfacesDom {
  OesStandardDerivativesImpl.internal_() : super.internal_();
  get runtimeType => OesStandardDerivatives;
  toString() => super.toString();
}
@patch class OesTextureFloat {
  static Type get instanceRuntimeType => OesTextureFloatImpl;

}
class OesTextureFloatImpl extends OesTextureFloat implements js_library.JSObjectInterfacesDom {
  OesTextureFloatImpl.internal_() : super.internal_();
  get runtimeType => OesTextureFloat;
  toString() => super.toString();
}
@patch class OesTextureFloatLinear {
  static Type get instanceRuntimeType => OesTextureFloatLinearImpl;

}
class OesTextureFloatLinearImpl extends OesTextureFloatLinear implements js_library.JSObjectInterfacesDom {
  OesTextureFloatLinearImpl.internal_() : super.internal_();
  get runtimeType => OesTextureFloatLinear;
  toString() => super.toString();
}
@patch class OesTextureHalfFloat {
  static Type get instanceRuntimeType => OesTextureHalfFloatImpl;

}
class OesTextureHalfFloatImpl extends OesTextureHalfFloat implements js_library.JSObjectInterfacesDom {
  OesTextureHalfFloatImpl.internal_() : super.internal_();
  get runtimeType => OesTextureHalfFloat;
  toString() => super.toString();
}
@patch class OesTextureHalfFloatLinear {
  static Type get instanceRuntimeType => OesTextureHalfFloatLinearImpl;

}
class OesTextureHalfFloatLinearImpl extends OesTextureHalfFloatLinear implements js_library.JSObjectInterfacesDom {
  OesTextureHalfFloatLinearImpl.internal_() : super.internal_();
  get runtimeType => OesTextureHalfFloatLinear;
  toString() => super.toString();
}
@patch class OesVertexArrayObject {
  static Type get instanceRuntimeType => OesVertexArrayObjectImpl;

}
class OesVertexArrayObjectImpl extends OesVertexArrayObject implements js_library.JSObjectInterfacesDom {
  OesVertexArrayObjectImpl.internal_() : super.internal_();
  get runtimeType => OesVertexArrayObject;
  toString() => super.toString();
}
@patch class Program {
  static Type get instanceRuntimeType => ProgramImpl;

}
class ProgramImpl extends Program implements js_library.JSObjectInterfacesDom {
  ProgramImpl.internal_() : super.internal_();
  get runtimeType => Program;
  toString() => super.toString();
}
@patch class Query {
  static Type get instanceRuntimeType => QueryImpl;

}
class QueryImpl extends Query implements js_library.JSObjectInterfacesDom {
  QueryImpl.internal_() : super.internal_();
  get runtimeType => Query;
  toString() => super.toString();
}
@patch class Renderbuffer {
  static Type get instanceRuntimeType => RenderbufferImpl;

}
class RenderbufferImpl extends Renderbuffer implements js_library.JSObjectInterfacesDom {
  RenderbufferImpl.internal_() : super.internal_();
  get runtimeType => Renderbuffer;
  toString() => super.toString();
}
@patch class RenderingContext {
  static Type get instanceRuntimeType => RenderingContextImpl;

}
class RenderingContextImpl extends RenderingContext implements js_library.JSObjectInterfacesDom {
  RenderingContextImpl.internal_() : super.internal_();
  get runtimeType => RenderingContext;
  toString() => super.toString();
}
@patch class RenderingContext2 {
  static Type get instanceRuntimeType => RenderingContext2Impl;

}
class RenderingContext2Impl extends RenderingContext2 implements js_library.JSObjectInterfacesDom {
  RenderingContext2Impl.internal_() : super.internal_();
  get runtimeType => RenderingContext2;
  toString() => super.toString();
}
@patch class Sampler {
  static Type get instanceRuntimeType => SamplerImpl;

}
class SamplerImpl extends Sampler implements js_library.JSObjectInterfacesDom {
  SamplerImpl.internal_() : super.internal_();
  get runtimeType => Sampler;
  toString() => super.toString();
}
@patch class Shader {
  static Type get instanceRuntimeType => ShaderImpl;

}
class ShaderImpl extends Shader implements js_library.JSObjectInterfacesDom {
  ShaderImpl.internal_() : super.internal_();
  get runtimeType => Shader;
  toString() => super.toString();
}
@patch class ShaderPrecisionFormat {
  static Type get instanceRuntimeType => ShaderPrecisionFormatImpl;

}
class ShaderPrecisionFormatImpl extends ShaderPrecisionFormat implements js_library.JSObjectInterfacesDom {
  ShaderPrecisionFormatImpl.internal_() : super.internal_();
  get runtimeType => ShaderPrecisionFormat;
  toString() => super.toString();
}
@patch class Sync {
  static Type get instanceRuntimeType => SyncImpl;

}
class SyncImpl extends Sync implements js_library.JSObjectInterfacesDom {
  SyncImpl.internal_() : super.internal_();
  get runtimeType => Sync;
  toString() => super.toString();
}
@patch class Texture {
  static Type get instanceRuntimeType => TextureImpl;

}
class TextureImpl extends Texture implements js_library.JSObjectInterfacesDom {
  TextureImpl.internal_() : super.internal_();
  get runtimeType => Texture;
  toString() => super.toString();
}
@patch class TimerQueryExt {
  static Type get instanceRuntimeType => TimerQueryExtImpl;

}
class TimerQueryExtImpl extends TimerQueryExt implements js_library.JSObjectInterfacesDom {
  TimerQueryExtImpl.internal_() : super.internal_();
  get runtimeType => TimerQueryExt;
  toString() => super.toString();
}
@patch class TransformFeedback {
  static Type get instanceRuntimeType => TransformFeedbackImpl;

}
class TransformFeedbackImpl extends TransformFeedback implements js_library.JSObjectInterfacesDom {
  TransformFeedbackImpl.internal_() : super.internal_();
  get runtimeType => TransformFeedback;
  toString() => super.toString();
}
@patch class UniformLocation {
  static Type get instanceRuntimeType => UniformLocationImpl;

}
class UniformLocationImpl extends UniformLocation implements js_library.JSObjectInterfacesDom {
  UniformLocationImpl.internal_() : super.internal_();
  get runtimeType => UniformLocation;
  toString() => super.toString();
}
@patch class VertexArrayObject {
  static Type get instanceRuntimeType => VertexArrayObjectImpl;

}
class VertexArrayObjectImpl extends VertexArrayObject implements js_library.JSObjectInterfacesDom {
  VertexArrayObjectImpl.internal_() : super.internal_();
  get runtimeType => VertexArrayObject;
  toString() => super.toString();
}
@patch class VertexArrayObjectOes {
  static Type get instanceRuntimeType => VertexArrayObjectOesImpl;

}
class VertexArrayObjectOesImpl extends VertexArrayObjectOes implements js_library.JSObjectInterfacesDom {
  VertexArrayObjectOesImpl.internal_() : super.internal_();
  get runtimeType => VertexArrayObjectOes;
  toString() => super.toString();
}
@patch class _WebGL2RenderingContextBase {
  static Type get instanceRuntimeType => _WebGL2RenderingContextBaseImpl;

}
class _WebGL2RenderingContextBaseImpl extends _WebGL2RenderingContextBase implements js_library.JSObjectInterfacesDom {
  _WebGL2RenderingContextBaseImpl.internal_() : super.internal_();
  get runtimeType => _WebGL2RenderingContextBase;
  toString() => super.toString();
}
@patch class _WebGLRenderingContextBase {
  static Type get instanceRuntimeType => _WebGLRenderingContextBaseImpl;

}
class _WebGLRenderingContextBaseImpl extends _WebGLRenderingContextBase implements js_library.JSObjectInterfacesDom {
  _WebGLRenderingContextBaseImpl.internal_() : super.internal_();
  get runtimeType => _WebGLRenderingContextBase;
  toString() => super.toString();
}

"""
  ],
  "dart:web_sql": [
    "dart:web_sql",
    "dart:web_sql_js_interop_patch.dart",
    """import 'dart:js' as js_library;

/**
 * Placeholder object for cases where we need to determine exactly how many
 * args were passed to a function.
 */
const _UNDEFINED_JS_CONST = const Object();

@patch class SqlDatabase {
  static Type get instanceRuntimeType => SqlDatabaseImpl;

}
class SqlDatabaseImpl extends SqlDatabase implements js_library.JSObjectInterfacesDom {
  SqlDatabaseImpl.internal_() : super.internal_();
  get runtimeType => SqlDatabase;
  toString() => super.toString();
}
@patch class SqlError {
  static Type get instanceRuntimeType => SqlErrorImpl;

}
class SqlErrorImpl extends SqlError implements js_library.JSObjectInterfacesDom {
  SqlErrorImpl.internal_() : super.internal_();
  get runtimeType => SqlError;
  toString() => super.toString();
}
@patch class SqlResultSet {
  static Type get instanceRuntimeType => SqlResultSetImpl;

}
class SqlResultSetImpl extends SqlResultSet implements js_library.JSObjectInterfacesDom {
  SqlResultSetImpl.internal_() : super.internal_();
  get runtimeType => SqlResultSet;
  toString() => super.toString();
}
@patch class SqlResultSetRowList {
  static Type get instanceRuntimeType => SqlResultSetRowListImpl;

}
class SqlResultSetRowListImpl extends SqlResultSetRowList implements js_library.JSObjectInterfacesDom {
  SqlResultSetRowListImpl.internal_() : super.internal_();
  get runtimeType => SqlResultSetRowList;
  toString() => super.toString();
}
@patch class SqlTransaction {
  static Type get instanceRuntimeType => SqlTransactionImpl;

}
class SqlTransactionImpl extends SqlTransaction implements js_library.JSObjectInterfacesDom {
  SqlTransactionImpl.internal_() : super.internal_();
  get runtimeType => SqlTransaction;
  toString() => super.toString();
}

"""
  ],
  "dart:svg": [
    "dart:svg",
    "dart:svg_js_interop_patch.dart",
    """import 'dart:js' as js_library;

/**
 * Placeholder object for cases where we need to determine exactly how many
 * args were passed to a function.
 */
const _UNDEFINED_JS_CONST = const Object();

@patch class AElement {
  static Type get instanceRuntimeType => AElementImpl;

}
class AElementImpl extends AElement implements js_library.JSObjectInterfacesDom {
  AElementImpl.internal_() : super.internal_();
  get runtimeType => AElement;
  toString() => super.toString();
}
@patch class Angle {
  static Type get instanceRuntimeType => AngleImpl;

}
class AngleImpl extends Angle implements js_library.JSObjectInterfacesDom {
  AngleImpl.internal_() : super.internal_();
  get runtimeType => Angle;
  toString() => super.toString();
}
@patch class AnimateElement {
  static Type get instanceRuntimeType => AnimateElementImpl;

}
class AnimateElementImpl extends AnimateElement implements js_library.JSObjectInterfacesDom {
  AnimateElementImpl.internal_() : super.internal_();
  get runtimeType => AnimateElement;
  toString() => super.toString();
}
@patch class AnimateMotionElement {
  static Type get instanceRuntimeType => AnimateMotionElementImpl;

}
class AnimateMotionElementImpl extends AnimateMotionElement implements js_library.JSObjectInterfacesDom {
  AnimateMotionElementImpl.internal_() : super.internal_();
  get runtimeType => AnimateMotionElement;
  toString() => super.toString();
}
@patch class AnimateTransformElement {
  static Type get instanceRuntimeType => AnimateTransformElementImpl;

}
class AnimateTransformElementImpl extends AnimateTransformElement implements js_library.JSObjectInterfacesDom {
  AnimateTransformElementImpl.internal_() : super.internal_();
  get runtimeType => AnimateTransformElement;
  toString() => super.toString();
}
@patch class AnimatedAngle {
  static Type get instanceRuntimeType => AnimatedAngleImpl;

}
class AnimatedAngleImpl extends AnimatedAngle implements js_library.JSObjectInterfacesDom {
  AnimatedAngleImpl.internal_() : super.internal_();
  get runtimeType => AnimatedAngle;
  toString() => super.toString();
}
@patch class AnimatedBoolean {
  static Type get instanceRuntimeType => AnimatedBooleanImpl;

}
class AnimatedBooleanImpl extends AnimatedBoolean implements js_library.JSObjectInterfacesDom {
  AnimatedBooleanImpl.internal_() : super.internal_();
  get runtimeType => AnimatedBoolean;
  toString() => super.toString();
}
@patch class AnimatedEnumeration {
  static Type get instanceRuntimeType => AnimatedEnumerationImpl;

}
class AnimatedEnumerationImpl extends AnimatedEnumeration implements js_library.JSObjectInterfacesDom {
  AnimatedEnumerationImpl.internal_() : super.internal_();
  get runtimeType => AnimatedEnumeration;
  toString() => super.toString();
}
@patch class AnimatedInteger {
  static Type get instanceRuntimeType => AnimatedIntegerImpl;

}
class AnimatedIntegerImpl extends AnimatedInteger implements js_library.JSObjectInterfacesDom {
  AnimatedIntegerImpl.internal_() : super.internal_();
  get runtimeType => AnimatedInteger;
  toString() => super.toString();
}
@patch class AnimatedLength {
  static Type get instanceRuntimeType => AnimatedLengthImpl;

}
class AnimatedLengthImpl extends AnimatedLength implements js_library.JSObjectInterfacesDom {
  AnimatedLengthImpl.internal_() : super.internal_();
  get runtimeType => AnimatedLength;
  toString() => super.toString();
}
@patch class AnimatedLengthList {
  static Type get instanceRuntimeType => AnimatedLengthListImpl;

}
class AnimatedLengthListImpl extends AnimatedLengthList implements js_library.JSObjectInterfacesDom {
  AnimatedLengthListImpl.internal_() : super.internal_();
  get runtimeType => AnimatedLengthList;
  toString() => super.toString();
}
@patch class AnimatedNumber {
  static Type get instanceRuntimeType => AnimatedNumberImpl;

}
class AnimatedNumberImpl extends AnimatedNumber implements js_library.JSObjectInterfacesDom {
  AnimatedNumberImpl.internal_() : super.internal_();
  get runtimeType => AnimatedNumber;
  toString() => super.toString();
}
@patch class AnimatedNumberList {
  static Type get instanceRuntimeType => AnimatedNumberListImpl;

}
class AnimatedNumberListImpl extends AnimatedNumberList implements js_library.JSObjectInterfacesDom {
  AnimatedNumberListImpl.internal_() : super.internal_();
  get runtimeType => AnimatedNumberList;
  toString() => super.toString();
}
@patch class AnimatedPreserveAspectRatio {
  static Type get instanceRuntimeType => AnimatedPreserveAspectRatioImpl;

}
class AnimatedPreserveAspectRatioImpl extends AnimatedPreserveAspectRatio implements js_library.JSObjectInterfacesDom {
  AnimatedPreserveAspectRatioImpl.internal_() : super.internal_();
  get runtimeType => AnimatedPreserveAspectRatio;
  toString() => super.toString();
}
@patch class AnimatedRect {
  static Type get instanceRuntimeType => AnimatedRectImpl;

}
class AnimatedRectImpl extends AnimatedRect implements js_library.JSObjectInterfacesDom {
  AnimatedRectImpl.internal_() : super.internal_();
  get runtimeType => AnimatedRect;
  toString() => super.toString();
}
@patch class AnimatedString {
  static Type get instanceRuntimeType => AnimatedStringImpl;

}
class AnimatedStringImpl extends AnimatedString implements js_library.JSObjectInterfacesDom {
  AnimatedStringImpl.internal_() : super.internal_();
  get runtimeType => AnimatedString;
  toString() => super.toString();
}
@patch class AnimatedTransformList {
  static Type get instanceRuntimeType => AnimatedTransformListImpl;

}
class AnimatedTransformListImpl extends AnimatedTransformList implements js_library.JSObjectInterfacesDom {
  AnimatedTransformListImpl.internal_() : super.internal_();
  get runtimeType => AnimatedTransformList;
  toString() => super.toString();
}
@patch class AnimationElement {
  static Type get instanceRuntimeType => AnimationElementImpl;

}
class AnimationElementImpl extends AnimationElement implements js_library.JSObjectInterfacesDom {
  AnimationElementImpl.internal_() : super.internal_();
  get runtimeType => AnimationElement;
  toString() => super.toString();
}
@patch class CircleElement {
  static Type get instanceRuntimeType => CircleElementImpl;

}
class CircleElementImpl extends CircleElement implements js_library.JSObjectInterfacesDom {
  CircleElementImpl.internal_() : super.internal_();
  get runtimeType => CircleElement;
  toString() => super.toString();
}
@patch class ClipPathElement {
  static Type get instanceRuntimeType => ClipPathElementImpl;

}
class ClipPathElementImpl extends ClipPathElement implements js_library.JSObjectInterfacesDom {
  ClipPathElementImpl.internal_() : super.internal_();
  get runtimeType => ClipPathElement;
  toString() => super.toString();
}
@patch class DefsElement {
  static Type get instanceRuntimeType => DefsElementImpl;

}
class DefsElementImpl extends DefsElement implements js_library.JSObjectInterfacesDom {
  DefsElementImpl.internal_() : super.internal_();
  get runtimeType => DefsElement;
  toString() => super.toString();
}
@patch class DescElement {
  static Type get instanceRuntimeType => DescElementImpl;

}
class DescElementImpl extends DescElement implements js_library.JSObjectInterfacesDom {
  DescElementImpl.internal_() : super.internal_();
  get runtimeType => DescElement;
  toString() => super.toString();
}
@patch class DiscardElement {
  static Type get instanceRuntimeType => DiscardElementImpl;

}
class DiscardElementImpl extends DiscardElement implements js_library.JSObjectInterfacesDom {
  DiscardElementImpl.internal_() : super.internal_();
  get runtimeType => DiscardElement;
  toString() => super.toString();
}
@patch class EllipseElement {
  static Type get instanceRuntimeType => EllipseElementImpl;

}
class EllipseElementImpl extends EllipseElement implements js_library.JSObjectInterfacesDom {
  EllipseElementImpl.internal_() : super.internal_();
  get runtimeType => EllipseElement;
  toString() => super.toString();
}
@patch class FEBlendElement {
  static Type get instanceRuntimeType => FEBlendElementImpl;

}
class FEBlendElementImpl extends FEBlendElement implements js_library.JSObjectInterfacesDom {
  FEBlendElementImpl.internal_() : super.internal_();
  get runtimeType => FEBlendElement;
  toString() => super.toString();
}
@patch class FEColorMatrixElement {
  static Type get instanceRuntimeType => FEColorMatrixElementImpl;

}
class FEColorMatrixElementImpl extends FEColorMatrixElement implements js_library.JSObjectInterfacesDom {
  FEColorMatrixElementImpl.internal_() : super.internal_();
  get runtimeType => FEColorMatrixElement;
  toString() => super.toString();
}
@patch class FEComponentTransferElement {
  static Type get instanceRuntimeType => FEComponentTransferElementImpl;

}
class FEComponentTransferElementImpl extends FEComponentTransferElement implements js_library.JSObjectInterfacesDom {
  FEComponentTransferElementImpl.internal_() : super.internal_();
  get runtimeType => FEComponentTransferElement;
  toString() => super.toString();
}
@patch class FECompositeElement {
  static Type get instanceRuntimeType => FECompositeElementImpl;

}
class FECompositeElementImpl extends FECompositeElement implements js_library.JSObjectInterfacesDom {
  FECompositeElementImpl.internal_() : super.internal_();
  get runtimeType => FECompositeElement;
  toString() => super.toString();
}
@patch class FEConvolveMatrixElement {
  static Type get instanceRuntimeType => FEConvolveMatrixElementImpl;

}
class FEConvolveMatrixElementImpl extends FEConvolveMatrixElement implements js_library.JSObjectInterfacesDom {
  FEConvolveMatrixElementImpl.internal_() : super.internal_();
  get runtimeType => FEConvolveMatrixElement;
  toString() => super.toString();
}
@patch class FEDiffuseLightingElement {
  static Type get instanceRuntimeType => FEDiffuseLightingElementImpl;

}
class FEDiffuseLightingElementImpl extends FEDiffuseLightingElement implements js_library.JSObjectInterfacesDom {
  FEDiffuseLightingElementImpl.internal_() : super.internal_();
  get runtimeType => FEDiffuseLightingElement;
  toString() => super.toString();
}
@patch class FEDisplacementMapElement {
  static Type get instanceRuntimeType => FEDisplacementMapElementImpl;

}
class FEDisplacementMapElementImpl extends FEDisplacementMapElement implements js_library.JSObjectInterfacesDom {
  FEDisplacementMapElementImpl.internal_() : super.internal_();
  get runtimeType => FEDisplacementMapElement;
  toString() => super.toString();
}
@patch class FEDistantLightElement {
  static Type get instanceRuntimeType => FEDistantLightElementImpl;

}
class FEDistantLightElementImpl extends FEDistantLightElement implements js_library.JSObjectInterfacesDom {
  FEDistantLightElementImpl.internal_() : super.internal_();
  get runtimeType => FEDistantLightElement;
  toString() => super.toString();
}
@patch class FEFloodElement {
  static Type get instanceRuntimeType => FEFloodElementImpl;

}
class FEFloodElementImpl extends FEFloodElement implements js_library.JSObjectInterfacesDom {
  FEFloodElementImpl.internal_() : super.internal_();
  get runtimeType => FEFloodElement;
  toString() => super.toString();
}
@patch class FEFuncAElement {
  static Type get instanceRuntimeType => FEFuncAElementImpl;

}
class FEFuncAElementImpl extends FEFuncAElement implements js_library.JSObjectInterfacesDom {
  FEFuncAElementImpl.internal_() : super.internal_();
  get runtimeType => FEFuncAElement;
  toString() => super.toString();
}
@patch class FEFuncBElement {
  static Type get instanceRuntimeType => FEFuncBElementImpl;

}
class FEFuncBElementImpl extends FEFuncBElement implements js_library.JSObjectInterfacesDom {
  FEFuncBElementImpl.internal_() : super.internal_();
  get runtimeType => FEFuncBElement;
  toString() => super.toString();
}
@patch class FEFuncGElement {
  static Type get instanceRuntimeType => FEFuncGElementImpl;

}
class FEFuncGElementImpl extends FEFuncGElement implements js_library.JSObjectInterfacesDom {
  FEFuncGElementImpl.internal_() : super.internal_();
  get runtimeType => FEFuncGElement;
  toString() => super.toString();
}
@patch class FEFuncRElement {
  static Type get instanceRuntimeType => FEFuncRElementImpl;

}
class FEFuncRElementImpl extends FEFuncRElement implements js_library.JSObjectInterfacesDom {
  FEFuncRElementImpl.internal_() : super.internal_();
  get runtimeType => FEFuncRElement;
  toString() => super.toString();
}
@patch class FEGaussianBlurElement {
  static Type get instanceRuntimeType => FEGaussianBlurElementImpl;

}
class FEGaussianBlurElementImpl extends FEGaussianBlurElement implements js_library.JSObjectInterfacesDom {
  FEGaussianBlurElementImpl.internal_() : super.internal_();
  get runtimeType => FEGaussianBlurElement;
  toString() => super.toString();
}
@patch class FEImageElement {
  static Type get instanceRuntimeType => FEImageElementImpl;

}
class FEImageElementImpl extends FEImageElement implements js_library.JSObjectInterfacesDom {
  FEImageElementImpl.internal_() : super.internal_();
  get runtimeType => FEImageElement;
  toString() => super.toString();
}
@patch class FEMergeElement {
  static Type get instanceRuntimeType => FEMergeElementImpl;

}
class FEMergeElementImpl extends FEMergeElement implements js_library.JSObjectInterfacesDom {
  FEMergeElementImpl.internal_() : super.internal_();
  get runtimeType => FEMergeElement;
  toString() => super.toString();
}
@patch class FEMergeNodeElement {
  static Type get instanceRuntimeType => FEMergeNodeElementImpl;

}
class FEMergeNodeElementImpl extends FEMergeNodeElement implements js_library.JSObjectInterfacesDom {
  FEMergeNodeElementImpl.internal_() : super.internal_();
  get runtimeType => FEMergeNodeElement;
  toString() => super.toString();
}
@patch class FEMorphologyElement {
  static Type get instanceRuntimeType => FEMorphologyElementImpl;

}
class FEMorphologyElementImpl extends FEMorphologyElement implements js_library.JSObjectInterfacesDom {
  FEMorphologyElementImpl.internal_() : super.internal_();
  get runtimeType => FEMorphologyElement;
  toString() => super.toString();
}
@patch class FEOffsetElement {
  static Type get instanceRuntimeType => FEOffsetElementImpl;

}
class FEOffsetElementImpl extends FEOffsetElement implements js_library.JSObjectInterfacesDom {
  FEOffsetElementImpl.internal_() : super.internal_();
  get runtimeType => FEOffsetElement;
  toString() => super.toString();
}
@patch class FEPointLightElement {
  static Type get instanceRuntimeType => FEPointLightElementImpl;

}
class FEPointLightElementImpl extends FEPointLightElement implements js_library.JSObjectInterfacesDom {
  FEPointLightElementImpl.internal_() : super.internal_();
  get runtimeType => FEPointLightElement;
  toString() => super.toString();
}
@patch class FESpecularLightingElement {
  static Type get instanceRuntimeType => FESpecularLightingElementImpl;

}
class FESpecularLightingElementImpl extends FESpecularLightingElement implements js_library.JSObjectInterfacesDom {
  FESpecularLightingElementImpl.internal_() : super.internal_();
  get runtimeType => FESpecularLightingElement;
  toString() => super.toString();
}
@patch class FESpotLightElement {
  static Type get instanceRuntimeType => FESpotLightElementImpl;

}
class FESpotLightElementImpl extends FESpotLightElement implements js_library.JSObjectInterfacesDom {
  FESpotLightElementImpl.internal_() : super.internal_();
  get runtimeType => FESpotLightElement;
  toString() => super.toString();
}
@patch class FETileElement {
  static Type get instanceRuntimeType => FETileElementImpl;

}
class FETileElementImpl extends FETileElement implements js_library.JSObjectInterfacesDom {
  FETileElementImpl.internal_() : super.internal_();
  get runtimeType => FETileElement;
  toString() => super.toString();
}
@patch class FETurbulenceElement {
  static Type get instanceRuntimeType => FETurbulenceElementImpl;

}
class FETurbulenceElementImpl extends FETurbulenceElement implements js_library.JSObjectInterfacesDom {
  FETurbulenceElementImpl.internal_() : super.internal_();
  get runtimeType => FETurbulenceElement;
  toString() => super.toString();
}
@patch class FilterElement {
  static Type get instanceRuntimeType => FilterElementImpl;

}
class FilterElementImpl extends FilterElement implements js_library.JSObjectInterfacesDom {
  FilterElementImpl.internal_() : super.internal_();
  get runtimeType => FilterElement;
  toString() => super.toString();
}
@patch class FilterPrimitiveStandardAttributes {
  static Type get instanceRuntimeType => FilterPrimitiveStandardAttributesImpl;

}
class FilterPrimitiveStandardAttributesImpl extends FilterPrimitiveStandardAttributes implements js_library.JSObjectInterfacesDom {
  FilterPrimitiveStandardAttributesImpl.internal_() : super.internal_();
  get runtimeType => FilterPrimitiveStandardAttributes;
  toString() => super.toString();
}
@patch class FitToViewBox {
  static Type get instanceRuntimeType => FitToViewBoxImpl;

}
class FitToViewBoxImpl extends FitToViewBox implements js_library.JSObjectInterfacesDom {
  FitToViewBoxImpl.internal_() : super.internal_();
  get runtimeType => FitToViewBox;
  toString() => super.toString();
}
@patch class ForeignObjectElement {
  static Type get instanceRuntimeType => ForeignObjectElementImpl;

}
class ForeignObjectElementImpl extends ForeignObjectElement implements js_library.JSObjectInterfacesDom {
  ForeignObjectElementImpl.internal_() : super.internal_();
  get runtimeType => ForeignObjectElement;
  toString() => super.toString();
}
@patch class GElement {
  static Type get instanceRuntimeType => GElementImpl;

}
class GElementImpl extends GElement implements js_library.JSObjectInterfacesDom {
  GElementImpl.internal_() : super.internal_();
  get runtimeType => GElement;
  toString() => super.toString();
}
@patch class GeometryElement {
  static Type get instanceRuntimeType => GeometryElementImpl;

}
class GeometryElementImpl extends GeometryElement implements js_library.JSObjectInterfacesDom {
  GeometryElementImpl.internal_() : super.internal_();
  get runtimeType => GeometryElement;
  toString() => super.toString();
}
@patch class GraphicsElement {
  static Type get instanceRuntimeType => GraphicsElementImpl;

}
class GraphicsElementImpl extends GraphicsElement implements js_library.JSObjectInterfacesDom {
  GraphicsElementImpl.internal_() : super.internal_();
  get runtimeType => GraphicsElement;
  toString() => super.toString();
}
@patch class ImageElement {
  static Type get instanceRuntimeType => ImageElementImpl;

}
class ImageElementImpl extends ImageElement implements js_library.JSObjectInterfacesDom {
  ImageElementImpl.internal_() : super.internal_();
  get runtimeType => ImageElement;
  toString() => super.toString();
}
@patch class Length {
  static Type get instanceRuntimeType => LengthImpl;

}
class LengthImpl extends Length implements js_library.JSObjectInterfacesDom {
  LengthImpl.internal_() : super.internal_();
  get runtimeType => Length;
  toString() => super.toString();
}
@patch class LengthList {
  static Type get instanceRuntimeType => LengthListImpl;

}
class LengthListImpl extends LengthList implements js_library.JSObjectInterfacesDom {
  LengthListImpl.internal_() : super.internal_();
  get runtimeType => LengthList;
  toString() => super.toString();
}
@patch class LineElement {
  static Type get instanceRuntimeType => LineElementImpl;

}
class LineElementImpl extends LineElement implements js_library.JSObjectInterfacesDom {
  LineElementImpl.internal_() : super.internal_();
  get runtimeType => LineElement;
  toString() => super.toString();
}
@patch class LinearGradientElement {
  static Type get instanceRuntimeType => LinearGradientElementImpl;

}
class LinearGradientElementImpl extends LinearGradientElement implements js_library.JSObjectInterfacesDom {
  LinearGradientElementImpl.internal_() : super.internal_();
  get runtimeType => LinearGradientElement;
  toString() => super.toString();
}
@patch class MarkerElement {
  static Type get instanceRuntimeType => MarkerElementImpl;

}
class MarkerElementImpl extends MarkerElement implements js_library.JSObjectInterfacesDom {
  MarkerElementImpl.internal_() : super.internal_();
  get runtimeType => MarkerElement;
  toString() => super.toString();
}
@patch class MaskElement {
  static Type get instanceRuntimeType => MaskElementImpl;

}
class MaskElementImpl extends MaskElement implements js_library.JSObjectInterfacesDom {
  MaskElementImpl.internal_() : super.internal_();
  get runtimeType => MaskElement;
  toString() => super.toString();
}
@patch class Matrix {
  static Type get instanceRuntimeType => MatrixImpl;

}
class MatrixImpl extends Matrix implements js_library.JSObjectInterfacesDom {
  MatrixImpl.internal_() : super.internal_();
  get runtimeType => Matrix;
  toString() => super.toString();
}
@patch class MetadataElement {
  static Type get instanceRuntimeType => MetadataElementImpl;

}
class MetadataElementImpl extends MetadataElement implements js_library.JSObjectInterfacesDom {
  MetadataElementImpl.internal_() : super.internal_();
  get runtimeType => MetadataElement;
  toString() => super.toString();
}
@patch class Number {
  static Type get instanceRuntimeType => NumberImpl;

}
class NumberImpl extends Number implements js_library.JSObjectInterfacesDom {
  NumberImpl.internal_() : super.internal_();
  get runtimeType => Number;
  toString() => super.toString();
}
@patch class NumberList {
  static Type get instanceRuntimeType => NumberListImpl;

}
class NumberListImpl extends NumberList implements js_library.JSObjectInterfacesDom {
  NumberListImpl.internal_() : super.internal_();
  get runtimeType => NumberList;
  toString() => super.toString();
}
@patch class PathElement {
  static Type get instanceRuntimeType => PathElementImpl;

}
class PathElementImpl extends PathElement implements js_library.JSObjectInterfacesDom {
  PathElementImpl.internal_() : super.internal_();
  get runtimeType => PathElement;
  toString() => super.toString();
}
@patch class PatternElement {
  static Type get instanceRuntimeType => PatternElementImpl;

}
class PatternElementImpl extends PatternElement implements js_library.JSObjectInterfacesDom {
  PatternElementImpl.internal_() : super.internal_();
  get runtimeType => PatternElement;
  toString() => super.toString();
}
@patch class Point {
  static Type get instanceRuntimeType => PointImpl;

}
class PointImpl extends Point implements js_library.JSObjectInterfacesDom {
  PointImpl.internal_() : super.internal_();
  get runtimeType => Point;
  toString() => super.toString();
}
@patch class PointList {
  static Type get instanceRuntimeType => PointListImpl;

}
class PointListImpl extends PointList implements js_library.JSObjectInterfacesDom {
  PointListImpl.internal_() : super.internal_();
  get runtimeType => PointList;
  toString() => super.toString();
}
@patch class PolygonElement {
  static Type get instanceRuntimeType => PolygonElementImpl;

}
class PolygonElementImpl extends PolygonElement implements js_library.JSObjectInterfacesDom {
  PolygonElementImpl.internal_() : super.internal_();
  get runtimeType => PolygonElement;
  toString() => super.toString();
}
@patch class PolylineElement {
  static Type get instanceRuntimeType => PolylineElementImpl;

}
class PolylineElementImpl extends PolylineElement implements js_library.JSObjectInterfacesDom {
  PolylineElementImpl.internal_() : super.internal_();
  get runtimeType => PolylineElement;
  toString() => super.toString();
}
@patch class PreserveAspectRatio {
  static Type get instanceRuntimeType => PreserveAspectRatioImpl;

}
class PreserveAspectRatioImpl extends PreserveAspectRatio implements js_library.JSObjectInterfacesDom {
  PreserveAspectRatioImpl.internal_() : super.internal_();
  get runtimeType => PreserveAspectRatio;
  toString() => super.toString();
}
@patch class RadialGradientElement {
  static Type get instanceRuntimeType => RadialGradientElementImpl;

}
class RadialGradientElementImpl extends RadialGradientElement implements js_library.JSObjectInterfacesDom {
  RadialGradientElementImpl.internal_() : super.internal_();
  get runtimeType => RadialGradientElement;
  toString() => super.toString();
}
@patch class Rect {
  static Type get instanceRuntimeType => RectImpl;

}
class RectImpl extends Rect implements js_library.JSObjectInterfacesDom {
  RectImpl.internal_() : super.internal_();
  get runtimeType => Rect;
  toString() => super.toString();
}
@patch class RectElement {
  static Type get instanceRuntimeType => RectElementImpl;

}
class RectElementImpl extends RectElement implements js_library.JSObjectInterfacesDom {
  RectElementImpl.internal_() : super.internal_();
  get runtimeType => RectElement;
  toString() => super.toString();
}
@patch class ScriptElement {
  static Type get instanceRuntimeType => ScriptElementImpl;

}
class ScriptElementImpl extends ScriptElement implements js_library.JSObjectInterfacesDom {
  ScriptElementImpl.internal_() : super.internal_();
  get runtimeType => ScriptElement;
  toString() => super.toString();
}
@patch class SetElement {
  static Type get instanceRuntimeType => SetElementImpl;

}
class SetElementImpl extends SetElement implements js_library.JSObjectInterfacesDom {
  SetElementImpl.internal_() : super.internal_();
  get runtimeType => SetElement;
  toString() => super.toString();
}
@patch class StopElement {
  static Type get instanceRuntimeType => StopElementImpl;

}
class StopElementImpl extends StopElement implements js_library.JSObjectInterfacesDom {
  StopElementImpl.internal_() : super.internal_();
  get runtimeType => StopElement;
  toString() => super.toString();
}
@patch class StringList {
  static Type get instanceRuntimeType => StringListImpl;

}
class StringListImpl extends StringList implements js_library.JSObjectInterfacesDom {
  StringListImpl.internal_() : super.internal_();
  get runtimeType => StringList;
  toString() => super.toString();
}
@patch class StyleElement {
  static Type get instanceRuntimeType => StyleElementImpl;

}
class StyleElementImpl extends StyleElement implements js_library.JSObjectInterfacesDom {
  StyleElementImpl.internal_() : super.internal_();
  get runtimeType => StyleElement;
  toString() => super.toString();
}
@patch class SvgElement {
  static Type get instanceRuntimeType => SvgElementImpl;

}
class SvgElementImpl extends SvgElement implements js_library.JSObjectInterfacesDom {
  SvgElementImpl.internal_() : super.internal_();
  get runtimeType => SvgElement;
  toString() => super.toString();
}
@patch class SvgSvgElement {
  static Type get instanceRuntimeType => SvgSvgElementImpl;

}
class SvgSvgElementImpl extends SvgSvgElement implements js_library.JSObjectInterfacesDom {
  SvgSvgElementImpl.internal_() : super.internal_();
  get runtimeType => SvgSvgElement;
  toString() => super.toString();
}
@patch class SwitchElement {
  static Type get instanceRuntimeType => SwitchElementImpl;

}
class SwitchElementImpl extends SwitchElement implements js_library.JSObjectInterfacesDom {
  SwitchElementImpl.internal_() : super.internal_();
  get runtimeType => SwitchElement;
  toString() => super.toString();
}
@patch class SymbolElement {
  static Type get instanceRuntimeType => SymbolElementImpl;

}
class SymbolElementImpl extends SymbolElement implements js_library.JSObjectInterfacesDom {
  SymbolElementImpl.internal_() : super.internal_();
  get runtimeType => SymbolElement;
  toString() => super.toString();
}
@patch class TSpanElement {
  static Type get instanceRuntimeType => TSpanElementImpl;

}
class TSpanElementImpl extends TSpanElement implements js_library.JSObjectInterfacesDom {
  TSpanElementImpl.internal_() : super.internal_();
  get runtimeType => TSpanElement;
  toString() => super.toString();
}
@patch class Tests {
  static Type get instanceRuntimeType => TestsImpl;

}
class TestsImpl extends Tests implements js_library.JSObjectInterfacesDom {
  TestsImpl.internal_() : super.internal_();
  get runtimeType => Tests;
  toString() => super.toString();
}
@patch class TextContentElement {
  static Type get instanceRuntimeType => TextContentElementImpl;

}
class TextContentElementImpl extends TextContentElement implements js_library.JSObjectInterfacesDom {
  TextContentElementImpl.internal_() : super.internal_();
  get runtimeType => TextContentElement;
  toString() => super.toString();
}
@patch class TextElement {
  static Type get instanceRuntimeType => TextElementImpl;

}
class TextElementImpl extends TextElement implements js_library.JSObjectInterfacesDom {
  TextElementImpl.internal_() : super.internal_();
  get runtimeType => TextElement;
  toString() => super.toString();
}
@patch class TextPathElement {
  static Type get instanceRuntimeType => TextPathElementImpl;

}
class TextPathElementImpl extends TextPathElement implements js_library.JSObjectInterfacesDom {
  TextPathElementImpl.internal_() : super.internal_();
  get runtimeType => TextPathElement;
  toString() => super.toString();
}
@patch class TextPositioningElement {
  static Type get instanceRuntimeType => TextPositioningElementImpl;

}
class TextPositioningElementImpl extends TextPositioningElement implements js_library.JSObjectInterfacesDom {
  TextPositioningElementImpl.internal_() : super.internal_();
  get runtimeType => TextPositioningElement;
  toString() => super.toString();
}
@patch class TitleElement {
  static Type get instanceRuntimeType => TitleElementImpl;

}
class TitleElementImpl extends TitleElement implements js_library.JSObjectInterfacesDom {
  TitleElementImpl.internal_() : super.internal_();
  get runtimeType => TitleElement;
  toString() => super.toString();
}
@patch class Transform {
  static Type get instanceRuntimeType => TransformImpl;

}
class TransformImpl extends Transform implements js_library.JSObjectInterfacesDom {
  TransformImpl.internal_() : super.internal_();
  get runtimeType => Transform;
  toString() => super.toString();
}
@patch class TransformList {
  static Type get instanceRuntimeType => TransformListImpl;

}
class TransformListImpl extends TransformList implements js_library.JSObjectInterfacesDom {
  TransformListImpl.internal_() : super.internal_();
  get runtimeType => TransformList;
  toString() => super.toString();
}
@patch class UnitTypes {
  static Type get instanceRuntimeType => UnitTypesImpl;

}
class UnitTypesImpl extends UnitTypes implements js_library.JSObjectInterfacesDom {
  UnitTypesImpl.internal_() : super.internal_();
  get runtimeType => UnitTypes;
  toString() => super.toString();
}
@patch class UriReference {
  static Type get instanceRuntimeType => UriReferenceImpl;

}
class UriReferenceImpl extends UriReference implements js_library.JSObjectInterfacesDom {
  UriReferenceImpl.internal_() : super.internal_();
  get runtimeType => UriReference;
  toString() => super.toString();
}
@patch class UseElement {
  static Type get instanceRuntimeType => UseElementImpl;

}
class UseElementImpl extends UseElement implements js_library.JSObjectInterfacesDom {
  UseElementImpl.internal_() : super.internal_();
  get runtimeType => UseElement;
  toString() => super.toString();
}
@patch class ViewElement {
  static Type get instanceRuntimeType => ViewElementImpl;

}
class ViewElementImpl extends ViewElement implements js_library.JSObjectInterfacesDom {
  ViewElementImpl.internal_() : super.internal_();
  get runtimeType => ViewElement;
  toString() => super.toString();
}
@patch class ViewSpec {
  static Type get instanceRuntimeType => ViewSpecImpl;

}
class ViewSpecImpl extends ViewSpec implements js_library.JSObjectInterfacesDom {
  ViewSpecImpl.internal_() : super.internal_();
  get runtimeType => ViewSpec;
  toString() => super.toString();
}
@patch class ZoomAndPan {
  static Type get instanceRuntimeType => ZoomAndPanImpl;

}
class ZoomAndPanImpl extends ZoomAndPan implements js_library.JSObjectInterfacesDom {
  ZoomAndPanImpl.internal_() : super.internal_();
  get runtimeType => ZoomAndPan;
  toString() => super.toString();
}
@patch class ZoomEvent {
  static Type get instanceRuntimeType => ZoomEventImpl;

}
class ZoomEventImpl extends ZoomEvent implements js_library.JSObjectInterfacesDom {
  ZoomEventImpl.internal_() : super.internal_();
  get runtimeType => ZoomEvent;
  toString() => super.toString();
}
@patch class _GradientElement {
  static Type get instanceRuntimeType => _GradientElementImpl;

}
class _GradientElementImpl extends _GradientElement implements js_library.JSObjectInterfacesDom {
  _GradientElementImpl.internal_() : super.internal_();
  get runtimeType => _GradientElement;
  toString() => super.toString();
}
@patch class _SVGComponentTransferFunctionElement {
  static Type get instanceRuntimeType => _SVGComponentTransferFunctionElementImpl;

}
class _SVGComponentTransferFunctionElementImpl extends _SVGComponentTransferFunctionElement implements js_library.JSObjectInterfacesDom {
  _SVGComponentTransferFunctionElementImpl.internal_() : super.internal_();
  get runtimeType => _SVGComponentTransferFunctionElement;
  toString() => super.toString();
}
@patch class _SVGCursorElement {
  static Type get instanceRuntimeType => _SVGCursorElementImpl;

}
class _SVGCursorElementImpl extends _SVGCursorElement implements js_library.JSObjectInterfacesDom {
  _SVGCursorElementImpl.internal_() : super.internal_();
  get runtimeType => _SVGCursorElement;
  toString() => super.toString();
}
@patch class _SVGFEDropShadowElement {
  static Type get instanceRuntimeType => _SVGFEDropShadowElementImpl;

}
class _SVGFEDropShadowElementImpl extends _SVGFEDropShadowElement implements js_library.JSObjectInterfacesDom {
  _SVGFEDropShadowElementImpl.internal_() : super.internal_();
  get runtimeType => _SVGFEDropShadowElement;
  toString() => super.toString();
}
@patch class _SVGMPathElement {
  static Type get instanceRuntimeType => _SVGMPathElementImpl;

}
class _SVGMPathElementImpl extends _SVGMPathElement implements js_library.JSObjectInterfacesDom {
  _SVGMPathElementImpl.internal_() : super.internal_();
  get runtimeType => _SVGMPathElement;
  toString() => super.toString();
}

"""
  ],
  "dart:web_audio": [
    "dart:web_audio",
    "dart:web_audio_js_interop_patch.dart",
    """import 'dart:js' as js_library;

/**
 * Placeholder object for cases where we need to determine exactly how many
 * args were passed to a function.
 */
const _UNDEFINED_JS_CONST = const Object();

@patch class AnalyserNode {
  static Type get instanceRuntimeType => AnalyserNodeImpl;

}
class AnalyserNodeImpl extends AnalyserNode implements js_library.JSObjectInterfacesDom {
  AnalyserNodeImpl.internal_() : super.internal_();
  get runtimeType => AnalyserNode;
  toString() => super.toString();
}
@patch class AudioBuffer {
  static Type get instanceRuntimeType => AudioBufferImpl;

}
class AudioBufferImpl extends AudioBuffer implements js_library.JSObjectInterfacesDom {
  AudioBufferImpl.internal_() : super.internal_();
  get runtimeType => AudioBuffer;
  toString() => super.toString();
}
@patch class AudioBufferSourceNode {
  static Type get instanceRuntimeType => AudioBufferSourceNodeImpl;

}
class AudioBufferSourceNodeImpl extends AudioBufferSourceNode implements js_library.JSObjectInterfacesDom {
  AudioBufferSourceNodeImpl.internal_() : super.internal_();
  get runtimeType => AudioBufferSourceNode;
  toString() => super.toString();
}
@patch class AudioContext {
  static Type get instanceRuntimeType => AudioContextImpl;

}
class AudioContextImpl extends AudioContext implements js_library.JSObjectInterfacesDom {
  AudioContextImpl.internal_() : super.internal_();
  get runtimeType => AudioContext;
  toString() => super.toString();
}
@patch class AudioDestinationNode {
  static Type get instanceRuntimeType => AudioDestinationNodeImpl;

}
class AudioDestinationNodeImpl extends AudioDestinationNode implements js_library.JSObjectInterfacesDom {
  AudioDestinationNodeImpl.internal_() : super.internal_();
  get runtimeType => AudioDestinationNode;
  toString() => super.toString();
}
@patch class AudioListener {
  static Type get instanceRuntimeType => AudioListenerImpl;

}
class AudioListenerImpl extends AudioListener implements js_library.JSObjectInterfacesDom {
  AudioListenerImpl.internal_() : super.internal_();
  get runtimeType => AudioListener;
  toString() => super.toString();
}
@patch class AudioNode {
  static Type get instanceRuntimeType => AudioNodeImpl;

}
class AudioNodeImpl extends AudioNode implements js_library.JSObjectInterfacesDom {
  AudioNodeImpl.internal_() : super.internal_();
  get runtimeType => AudioNode;
  toString() => super.toString();
}
@patch class AudioParam {
  static Type get instanceRuntimeType => AudioParamImpl;

}
class AudioParamImpl extends AudioParam implements js_library.JSObjectInterfacesDom {
  AudioParamImpl.internal_() : super.internal_();
  get runtimeType => AudioParam;
  toString() => super.toString();
}
@patch class AudioProcessingEvent {
  static Type get instanceRuntimeType => AudioProcessingEventImpl;

}
class AudioProcessingEventImpl extends AudioProcessingEvent implements js_library.JSObjectInterfacesDom {
  AudioProcessingEventImpl.internal_() : super.internal_();
  get runtimeType => AudioProcessingEvent;
  toString() => super.toString();
}
@patch class AudioSourceNode {
  static Type get instanceRuntimeType => AudioSourceNodeImpl;

}
class AudioSourceNodeImpl extends AudioSourceNode implements js_library.JSObjectInterfacesDom {
  AudioSourceNodeImpl.internal_() : super.internal_();
  get runtimeType => AudioSourceNode;
  toString() => super.toString();
}
@patch class BiquadFilterNode {
  static Type get instanceRuntimeType => BiquadFilterNodeImpl;

}
class BiquadFilterNodeImpl extends BiquadFilterNode implements js_library.JSObjectInterfacesDom {
  BiquadFilterNodeImpl.internal_() : super.internal_();
  get runtimeType => BiquadFilterNode;
  toString() => super.toString();
}
@patch class ChannelMergerNode {
  static Type get instanceRuntimeType => ChannelMergerNodeImpl;

}
class ChannelMergerNodeImpl extends ChannelMergerNode implements js_library.JSObjectInterfacesDom {
  ChannelMergerNodeImpl.internal_() : super.internal_();
  get runtimeType => ChannelMergerNode;
  toString() => super.toString();
}
@patch class ChannelSplitterNode {
  static Type get instanceRuntimeType => ChannelSplitterNodeImpl;

}
class ChannelSplitterNodeImpl extends ChannelSplitterNode implements js_library.JSObjectInterfacesDom {
  ChannelSplitterNodeImpl.internal_() : super.internal_();
  get runtimeType => ChannelSplitterNode;
  toString() => super.toString();
}
@patch class ConvolverNode {
  static Type get instanceRuntimeType => ConvolverNodeImpl;

}
class ConvolverNodeImpl extends ConvolverNode implements js_library.JSObjectInterfacesDom {
  ConvolverNodeImpl.internal_() : super.internal_();
  get runtimeType => ConvolverNode;
  toString() => super.toString();
}
@patch class DelayNode {
  static Type get instanceRuntimeType => DelayNodeImpl;

}
class DelayNodeImpl extends DelayNode implements js_library.JSObjectInterfacesDom {
  DelayNodeImpl.internal_() : super.internal_();
  get runtimeType => DelayNode;
  toString() => super.toString();
}
@patch class DynamicsCompressorNode {
  static Type get instanceRuntimeType => DynamicsCompressorNodeImpl;

}
class DynamicsCompressorNodeImpl extends DynamicsCompressorNode implements js_library.JSObjectInterfacesDom {
  DynamicsCompressorNodeImpl.internal_() : super.internal_();
  get runtimeType => DynamicsCompressorNode;
  toString() => super.toString();
}
@patch class GainNode {
  static Type get instanceRuntimeType => GainNodeImpl;

}
class GainNodeImpl extends GainNode implements js_library.JSObjectInterfacesDom {
  GainNodeImpl.internal_() : super.internal_();
  get runtimeType => GainNode;
  toString() => super.toString();
}
@patch class IirFilterNode {
  static Type get instanceRuntimeType => IirFilterNodeImpl;

}
class IirFilterNodeImpl extends IirFilterNode implements js_library.JSObjectInterfacesDom {
  IirFilterNodeImpl.internal_() : super.internal_();
  get runtimeType => IirFilterNode;
  toString() => super.toString();
}
@patch class MediaElementAudioSourceNode {
  static Type get instanceRuntimeType => MediaElementAudioSourceNodeImpl;

}
class MediaElementAudioSourceNodeImpl extends MediaElementAudioSourceNode implements js_library.JSObjectInterfacesDom {
  MediaElementAudioSourceNodeImpl.internal_() : super.internal_();
  get runtimeType => MediaElementAudioSourceNode;
  toString() => super.toString();
}
@patch class MediaStreamAudioDestinationNode {
  static Type get instanceRuntimeType => MediaStreamAudioDestinationNodeImpl;

}
class MediaStreamAudioDestinationNodeImpl extends MediaStreamAudioDestinationNode implements js_library.JSObjectInterfacesDom {
  MediaStreamAudioDestinationNodeImpl.internal_() : super.internal_();
  get runtimeType => MediaStreamAudioDestinationNode;
  toString() => super.toString();
}
@patch class MediaStreamAudioSourceNode {
  static Type get instanceRuntimeType => MediaStreamAudioSourceNodeImpl;

}
class MediaStreamAudioSourceNodeImpl extends MediaStreamAudioSourceNode implements js_library.JSObjectInterfacesDom {
  MediaStreamAudioSourceNodeImpl.internal_() : super.internal_();
  get runtimeType => MediaStreamAudioSourceNode;
  toString() => super.toString();
}
@patch class OfflineAudioCompletionEvent {
  static Type get instanceRuntimeType => OfflineAudioCompletionEventImpl;

}
class OfflineAudioCompletionEventImpl extends OfflineAudioCompletionEvent implements js_library.JSObjectInterfacesDom {
  OfflineAudioCompletionEventImpl.internal_() : super.internal_();
  get runtimeType => OfflineAudioCompletionEvent;
  toString() => super.toString();
}
@patch class OfflineAudioContext {
  static Type get instanceRuntimeType => OfflineAudioContextImpl;

}
class OfflineAudioContextImpl extends OfflineAudioContext implements js_library.JSObjectInterfacesDom {
  OfflineAudioContextImpl.internal_() : super.internal_();
  get runtimeType => OfflineAudioContext;
  toString() => super.toString();
}
@patch class OscillatorNode {
  static Type get instanceRuntimeType => OscillatorNodeImpl;

}
class OscillatorNodeImpl extends OscillatorNode implements js_library.JSObjectInterfacesDom {
  OscillatorNodeImpl.internal_() : super.internal_();
  get runtimeType => OscillatorNode;
  toString() => super.toString();
}
@patch class PannerNode {
  static Type get instanceRuntimeType => PannerNodeImpl;

}
class PannerNodeImpl extends PannerNode implements js_library.JSObjectInterfacesDom {
  PannerNodeImpl.internal_() : super.internal_();
  get runtimeType => PannerNode;
  toString() => super.toString();
}
@patch class PeriodicWave {
  static Type get instanceRuntimeType => PeriodicWaveImpl;

}
class PeriodicWaveImpl extends PeriodicWave implements js_library.JSObjectInterfacesDom {
  PeriodicWaveImpl.internal_() : super.internal_();
  get runtimeType => PeriodicWave;
  toString() => super.toString();
}
@patch class ScriptProcessorNode {
  static Type get instanceRuntimeType => ScriptProcessorNodeImpl;

}
class ScriptProcessorNodeImpl extends ScriptProcessorNode implements js_library.JSObjectInterfacesDom {
  ScriptProcessorNodeImpl.internal_() : super.internal_();
  get runtimeType => ScriptProcessorNode;
  toString() => super.toString();
}
@patch class StereoPannerNode {
  static Type get instanceRuntimeType => StereoPannerNodeImpl;

}
class StereoPannerNodeImpl extends StereoPannerNode implements js_library.JSObjectInterfacesDom {
  StereoPannerNodeImpl.internal_() : super.internal_();
  get runtimeType => StereoPannerNode;
  toString() => super.toString();
}
@patch class WaveShaperNode {
  static Type get instanceRuntimeType => WaveShaperNodeImpl;

}
class WaveShaperNodeImpl extends WaveShaperNode implements js_library.JSObjectInterfacesDom {
  WaveShaperNodeImpl.internal_() : super.internal_();
  get runtimeType => WaveShaperNode;
  toString() => super.toString();
}

"""
  ],
};
// END_OF_CACHED_PATCHES
