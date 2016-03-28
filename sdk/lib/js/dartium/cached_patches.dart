// START_OF_CACHED_PATCHES
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT GENERATED FILE.

library cached_patches;

var cached_patches = {"dart:html": ["dart:html", "dart:html_js_interop_patch.dart", """import 'dart:js' as js_library;

/**
 * Placeholder object for cases where we need to determine exactly how many
 * args were passed to a function.
 */
const _UNDEFINED_JS_CONST = const Object();

patch class DivElement {
  factory DivElement._internalWrap() => new DivElementImpl.internal_();

}
class DivElementImpl extends DivElement implements js_library.JSObjectInterfacesDom {
  DivElementImpl.internal_() : super.internal_();
  get runtimeType => DivElement;
  toString() => super.toString();
}
patch class ImageElement {
  factory ImageElement._internalWrap() => new ImageElementImpl.internal_();

}
class ImageElementImpl extends ImageElement implements js_library.JSObjectInterfacesDom {
  ImageElementImpl.internal_() : super.internal_();
  get runtimeType => ImageElement;
  toString() => super.toString();
}
patch class TreeWalker {
  factory TreeWalker._internalWrap() => new TreeWalkerImpl.internal_();

}
class TreeWalkerImpl extends TreeWalker implements js_library.JSObjectInterfacesDom {
  TreeWalkerImpl.internal_() : super.internal_();
  get runtimeType => TreeWalker;
  toString() => super.toString();
}
patch class TableSectionElement {
  factory TableSectionElement._internalWrap() => new TableSectionElementImpl.internal_();

}
class TableSectionElementImpl extends TableSectionElement implements js_library.JSObjectInterfacesDom {
  TableSectionElementImpl.internal_() : super.internal_();
  get runtimeType => TableSectionElement;
  toString() => super.toString();
}
patch class DetailsElement {
  factory DetailsElement._internalWrap() => new DetailsElementImpl.internal_();

}
class DetailsElementImpl extends DetailsElement implements js_library.JSObjectInterfacesDom {
  DetailsElementImpl.internal_() : super.internal_();
  get runtimeType => DetailsElement;
  toString() => super.toString();
}
patch class XPathResult {
  factory XPathResult._internalWrap() => new XPathResultImpl.internal_();

}
class XPathResultImpl extends XPathResult implements js_library.JSObjectInterfacesDom {
  XPathResultImpl.internal_() : super.internal_();
  get runtimeType => XPathResult;
  toString() => super.toString();
}
patch class HttpRequest {
  factory HttpRequest._internalWrap() => new HttpRequestImpl.internal_();

}
class HttpRequestImpl extends HttpRequest implements js_library.JSObjectInterfacesDom {
  HttpRequestImpl.internal_() : super.internal_();
  get runtimeType => HttpRequest;
  toString() => super.toString();
}
patch class SpeechSynthesisUtterance {
  factory SpeechSynthesisUtterance._internalWrap() => new SpeechSynthesisUtteranceImpl.internal_();

}
class SpeechSynthesisUtteranceImpl extends SpeechSynthesisUtterance implements js_library.JSObjectInterfacesDom {
  SpeechSynthesisUtteranceImpl.internal_() : super.internal_();
  get runtimeType => SpeechSynthesisUtterance;
  toString() => super.toString();
}
patch class CredentialsContainer {
  factory CredentialsContainer._internalWrap() => new CredentialsContainerImpl.internal_();

}
class CredentialsContainerImpl extends CredentialsContainer implements js_library.JSObjectInterfacesDom {
  CredentialsContainerImpl.internal_() : super.internal_();
  get runtimeType => CredentialsContainer;
  toString() => super.toString();
}
patch class MessageChannel {
  factory MessageChannel._internalWrap() => new MessageChannelImpl.internal_();

}
class MessageChannelImpl extends MessageChannel implements js_library.JSObjectInterfacesDom {
  MessageChannelImpl.internal_() : super.internal_();
  get runtimeType => MessageChannel;
  toString() => super.toString();
}
patch class CloseEvent {
  factory CloseEvent._internalWrap() => new CloseEventImpl.internal_();

}
class CloseEventImpl extends CloseEvent implements js_library.JSObjectInterfacesDom {
  CloseEventImpl.internal_() : super.internal_();
  get runtimeType => CloseEvent;
  toString() => super.toString();
}
patch class ProgressEvent {
  factory ProgressEvent._internalWrap() => new ProgressEventImpl.internal_();

}
class ProgressEventImpl extends ProgressEvent implements js_library.JSObjectInterfacesDom {
  ProgressEventImpl.internal_() : super.internal_();
  get runtimeType => ProgressEvent;
  toString() => super.toString();
}
patch class MediaController {
  factory MediaController._internalWrap() => new MediaControllerImpl.internal_();

}
class MediaControllerImpl extends MediaController implements js_library.JSObjectInterfacesDom {
  MediaControllerImpl.internal_() : super.internal_();
  get runtimeType => MediaController;
  toString() => super.toString();
}
patch class VRDevice {
  factory VRDevice._internalWrap() => new VRDeviceImpl.internal_();

}
class VRDeviceImpl extends VRDevice implements js_library.JSObjectInterfacesDom {
  VRDeviceImpl.internal_() : super.internal_();
  get runtimeType => VRDevice;
  toString() => super.toString();
}
patch class SpeechSynthesis {
  factory SpeechSynthesis._internalWrap() => new SpeechSynthesisImpl.internal_();

}
class SpeechSynthesisImpl extends SpeechSynthesis implements js_library.JSObjectInterfacesDom {
  SpeechSynthesisImpl.internal_() : super.internal_();
  get runtimeType => SpeechSynthesis;
  toString() => super.toString();
}
patch class HtmlCollection {
  factory HtmlCollection._internalWrap() => new HtmlCollectionImpl.internal_();

}
class HtmlCollectionImpl extends HtmlCollection implements js_library.JSObjectInterfacesDom {
  HtmlCollectionImpl.internal_() : super.internal_();
  get runtimeType => HtmlCollection;
  toString() => super.toString();
}
patch class Element {
  factory Element._internalWrap() => new ElementImpl.internal_();

}
class ElementImpl extends Element implements js_library.JSObjectInterfacesDom {
  ElementImpl.internal_() : super.internal_();
  get runtimeType => Element;
  toString() => super.toString();
}
patch class Plugin {
  factory Plugin._internalWrap() => new PluginImpl.internal_();

}
class PluginImpl extends Plugin implements js_library.JSObjectInterfacesDom {
  PluginImpl.internal_() : super.internal_();
  get runtimeType => Plugin;
  toString() => super.toString();
}
patch class CssFontFaceRule {
  factory CssFontFaceRule._internalWrap() => new CssFontFaceRuleImpl.internal_();

}
class CssFontFaceRuleImpl extends CssFontFaceRule implements js_library.JSObjectInterfacesDom {
  CssFontFaceRuleImpl.internal_() : super.internal_();
  get runtimeType => CssFontFaceRule;
  toString() => super.toString();
}
patch class File {
  factory File._internalWrap() => new FileImpl.internal_();

}
class FileImpl extends File implements js_library.JSObjectInterfacesDom {
  FileImpl.internal_() : super.internal_();
  get runtimeType => File;
  toString() => super.toString();
}
patch class MouseEvent {
  factory MouseEvent._internalWrap() => new MouseEventImpl.internal_();

}
class MouseEventImpl extends MouseEvent implements js_library.JSObjectInterfacesDom {
  MouseEventImpl.internal_() : super.internal_();
  get runtimeType => MouseEvent;
  toString() => super.toString();
}
patch class MenuElement {
  factory MenuElement._internalWrap() => new MenuElementImpl.internal_();

}
class MenuElementImpl extends MenuElement implements js_library.JSObjectInterfacesDom {
  MenuElementImpl.internal_() : super.internal_();
  get runtimeType => MenuElement;
  toString() => super.toString();
}
patch class ReadableByteStreamReader {
  factory ReadableByteStreamReader._internalWrap() => new ReadableByteStreamReaderImpl.internal_();

}
class ReadableByteStreamReaderImpl extends ReadableByteStreamReader implements js_library.JSObjectInterfacesDom {
  ReadableByteStreamReaderImpl.internal_() : super.internal_();
  get runtimeType => ReadableByteStreamReader;
  toString() => super.toString();
}
patch class FetchEvent {
  factory FetchEvent._internalWrap() => new FetchEventImpl.internal_();

}
class FetchEventImpl extends FetchEvent implements js_library.JSObjectInterfacesDom {
  FetchEventImpl.internal_() : super.internal_();
  get runtimeType => FetchEvent;
  toString() => super.toString();
}
patch class MediaStreamTrack {
  factory MediaStreamTrack._internalWrap() => new MediaStreamTrackImpl.internal_();

}
class MediaStreamTrackImpl extends MediaStreamTrack implements js_library.JSObjectInterfacesDom {
  MediaStreamTrackImpl.internal_() : super.internal_();
  get runtimeType => MediaStreamTrack;
  toString() => super.toString();
}
patch class ShadowRoot {
  factory ShadowRoot._internalWrap() => new ShadowRootImpl.internal_();

}
class ShadowRootImpl extends ShadowRoot implements js_library.JSObjectInterfacesDom {
  ShadowRootImpl.internal_() : super.internal_();
  get runtimeType => ShadowRoot;
  toString() => super.toString();
}
patch class SpeechSynthesisEvent {
  factory SpeechSynthesisEvent._internalWrap() => new SpeechSynthesisEventImpl.internal_();

}
class SpeechSynthesisEventImpl extends SpeechSynthesisEvent implements js_library.JSObjectInterfacesDom {
  SpeechSynthesisEventImpl.internal_() : super.internal_();
  get runtimeType => SpeechSynthesisEvent;
  toString() => super.toString();
}
patch class VRPositionState {
  factory VRPositionState._internalWrap() => new VRPositionStateImpl.internal_();

}
class VRPositionStateImpl extends VRPositionState implements js_library.JSObjectInterfacesDom {
  VRPositionStateImpl.internal_() : super.internal_();
  get runtimeType => VRPositionState;
  toString() => super.toString();
}
patch class Window {
  factory Window._internalWrap() => new WindowImpl.internal_();

}
class WindowImpl extends Window implements js_library.JSObjectInterfacesDom {
  WindowImpl.internal_() : super.internal_();
  get runtimeType => Window;
  toString() => super.toString();
}
patch class SpeechRecognition {
  factory SpeechRecognition._internalWrap() => new SpeechRecognitionImpl.internal_();

}
class SpeechRecognitionImpl extends SpeechRecognition implements js_library.JSObjectInterfacesDom {
  SpeechRecognitionImpl.internal_() : super.internal_();
  get runtimeType => SpeechRecognition;
  toString() => super.toString();
}
patch class Console {
  factory Console._internalWrap() => new ConsoleImpl.internal_();

}
class ConsoleImpl extends Console implements js_library.JSObjectInterfacesDom {
  ConsoleImpl.internal_() : super.internal_();
  get runtimeType => Console;
  toString() => super.toString();
}
patch class AutocompleteErrorEvent {
  factory AutocompleteErrorEvent._internalWrap() => new AutocompleteErrorEventImpl.internal_();

}
class AutocompleteErrorEventImpl extends AutocompleteErrorEvent implements js_library.JSObjectInterfacesDom {
  AutocompleteErrorEventImpl.internal_() : super.internal_();
  get runtimeType => AutocompleteErrorEvent;
  toString() => super.toString();
}
patch class CanvasGradient {
  factory CanvasGradient._internalWrap() => new CanvasGradientImpl.internal_();

}
class CanvasGradientImpl extends CanvasGradient implements js_library.JSObjectInterfacesDom {
  CanvasGradientImpl.internal_() : super.internal_();
  get runtimeType => CanvasGradient;
  toString() => super.toString();
}
patch class MediaStream {
  factory MediaStream._internalWrap() => new MediaStreamImpl.internal_();

}
class MediaStreamImpl extends MediaStream implements js_library.JSObjectInterfacesDom {
  MediaStreamImpl.internal_() : super.internal_();
  get runtimeType => MediaStream;
  toString() => super.toString();
}
patch class _ClientRectList {
  factory _ClientRectList._internalWrap() => new _ClientRectListImpl.internal_();

}
class _ClientRectListImpl extends _ClientRectList implements js_library.JSObjectInterfacesDom {
  _ClientRectListImpl.internal_() : super.internal_();
  get runtimeType => _ClientRectList;
  toString() => super.toString();
}
patch class Document {
  factory Document._internalWrap() => new DocumentImpl.internal_();

}
class DocumentImpl extends Document implements js_library.JSObjectInterfacesDom {
  DocumentImpl.internal_() : super.internal_();
  get runtimeType => Document;
  toString() => super.toString();
}
patch class MessageEvent {
  factory MessageEvent._internalWrap() => new MessageEventImpl.internal_();

}
class MessageEventImpl extends MessageEvent implements js_library.JSObjectInterfacesDom {
  MessageEventImpl.internal_() : super.internal_();
  get runtimeType => MessageEvent;
  toString() => super.toString();
}
patch class RtcDtmfSender {
  factory RtcDtmfSender._internalWrap() => new RtcDtmfSenderImpl.internal_();

}
class RtcDtmfSenderImpl extends RtcDtmfSender implements js_library.JSObjectInterfacesDom {
  RtcDtmfSenderImpl.internal_() : super.internal_();
  get runtimeType => RtcDtmfSender;
  toString() => super.toString();
}
patch class ParamElement {
  factory ParamElement._internalWrap() => new ParamElementImpl.internal_();

}
class ParamElementImpl extends ParamElement implements js_library.JSObjectInterfacesDom {
  ParamElementImpl.internal_() : super.internal_();
  get runtimeType => ParamElement;
  toString() => super.toString();
}
patch class TextTrack {
  factory TextTrack._internalWrap() => new TextTrackImpl.internal_();

}
class TextTrackImpl extends TextTrack implements js_library.JSObjectInterfacesDom {
  TextTrackImpl.internal_() : super.internal_();
  get runtimeType => TextTrack;
  toString() => super.toString();
}
patch class ModElement {
  factory ModElement._internalWrap() => new ModElementImpl.internal_();

}
class ModElementImpl extends ModElement implements js_library.JSObjectInterfacesDom {
  ModElementImpl.internal_() : super.internal_();
  get runtimeType => ModElement;
  toString() => super.toString();
}
patch class ScriptElement {
  factory ScriptElement._internalWrap() => new ScriptElementImpl.internal_();

}
class ScriptElementImpl extends ScriptElement implements js_library.JSObjectInterfacesDom {
  ScriptElementImpl.internal_() : super.internal_();
  get runtimeType => ScriptElement;
  toString() => super.toString();
}
patch class VRFieldOfView {
  factory VRFieldOfView._internalWrap() => new VRFieldOfViewImpl.internal_();

}
class VRFieldOfViewImpl extends VRFieldOfView implements js_library.JSObjectInterfacesDom {
  VRFieldOfViewImpl.internal_() : super.internal_();
  get runtimeType => VRFieldOfView;
  toString() => super.toString();
}
patch class SyncRegistration {
  factory SyncRegistration._internalWrap() => new SyncRegistrationImpl.internal_();

}
class SyncRegistrationImpl extends SyncRegistration implements js_library.JSObjectInterfacesDom {
  SyncRegistrationImpl.internal_() : super.internal_();
  get runtimeType => SyncRegistration;
  toString() => super.toString();
}
patch class Touch {
  factory Touch._internalWrap() => new TouchImpl.internal_();

}
class TouchImpl extends Touch implements js_library.JSObjectInterfacesDom {
  TouchImpl.internal_() : super.internal_();
  get runtimeType => Touch;
  toString() => super.toString();
}
patch class BarProp {
  factory BarProp._internalWrap() => new BarPropImpl.internal_();

}
class BarPropImpl extends BarProp implements js_library.JSObjectInterfacesDom {
  BarPropImpl.internal_() : super.internal_();
  get runtimeType => BarProp;
  toString() => super.toString();
}
patch class DeviceLightEvent {
  factory DeviceLightEvent._internalWrap() => new DeviceLightEventImpl.internal_();

}
class DeviceLightEventImpl extends DeviceLightEvent implements js_library.JSObjectInterfacesDom {
  DeviceLightEventImpl.internal_() : super.internal_();
  get runtimeType => DeviceLightEvent;
  toString() => super.toString();
}
patch class MediaDevices {
  factory MediaDevices._internalWrap() => new MediaDevicesImpl.internal_();

}
class MediaDevicesImpl extends MediaDevices implements js_library.JSObjectInterfacesDom {
  MediaDevicesImpl.internal_() : super.internal_();
  get runtimeType => MediaDevices;
  toString() => super.toString();
}
patch class Url {
  factory Url._internalWrap() => new UrlImpl.internal_();

}
class UrlImpl extends Url implements js_library.JSObjectInterfacesDom {
  UrlImpl.internal_() : super.internal_();
  get runtimeType => Url;
  toString() => super.toString();
}
patch class EmbedElement {
  factory EmbedElement._internalWrap() => new EmbedElementImpl.internal_();

}
class EmbedElementImpl extends EmbedElement implements js_library.JSObjectInterfacesDom {
  EmbedElementImpl.internal_() : super.internal_();
  get runtimeType => EmbedElement;
  toString() => super.toString();
}
patch class Metadata {
  factory Metadata._internalWrap() => new MetadataImpl.internal_();

}
class MetadataImpl extends Metadata implements js_library.JSObjectInterfacesDom {
  MetadataImpl.internal_() : super.internal_();
  get runtimeType => Metadata;
  toString() => super.toString();
}
patch class _FileEntrySync {
  factory _FileEntrySync._internalWrap() => new _FileEntrySyncImpl.internal_();

}
class _FileEntrySyncImpl extends _FileEntrySync implements js_library.JSObjectInterfacesDom {
  _FileEntrySyncImpl.internal_() : super.internal_();
  get runtimeType => _FileEntrySync;
  toString() => super.toString();
}
patch class BaseElement {
  factory BaseElement._internalWrap() => new BaseElementImpl.internal_();

}
class BaseElementImpl extends BaseElement implements js_library.JSObjectInterfacesDom {
  BaseElementImpl.internal_() : super.internal_();
  get runtimeType => BaseElement;
  toString() => super.toString();
}
patch class BRElement {
  factory BRElement._internalWrap() => new BRElementImpl.internal_();

}
class BRElementImpl extends BRElement implements js_library.JSObjectInterfacesDom {
  BRElementImpl.internal_() : super.internal_();
  get runtimeType => BRElement;
  toString() => super.toString();
}
patch class Presentation {
  factory Presentation._internalWrap() => new PresentationImpl.internal_();

}
class PresentationImpl extends Presentation implements js_library.JSObjectInterfacesDom {
  PresentationImpl.internal_() : super.internal_();
  get runtimeType => Presentation;
  toString() => super.toString();
}
patch class CircularGeofencingRegion {
  factory CircularGeofencingRegion._internalWrap() => new CircularGeofencingRegionImpl.internal_();

}
class CircularGeofencingRegionImpl extends CircularGeofencingRegion implements js_library.JSObjectInterfacesDom {
  CircularGeofencingRegionImpl.internal_() : super.internal_();
  get runtimeType => CircularGeofencingRegion;
  toString() => super.toString();
}
patch class PushManager {
  factory PushManager._internalWrap() => new PushManagerImpl.internal_();

}
class PushManagerImpl extends PushManager implements js_library.JSObjectInterfacesDom {
  PushManagerImpl.internal_() : super.internal_();
  get runtimeType => PushManager;
  toString() => super.toString();
}
patch class PasswordCredential {
  factory PasswordCredential._internalWrap() => new PasswordCredentialImpl.internal_();

}
class PasswordCredentialImpl extends PasswordCredential implements js_library.JSObjectInterfacesDom {
  PasswordCredentialImpl.internal_() : super.internal_();
  get runtimeType => PasswordCredential;
  toString() => super.toString();
}
patch class ObjectElement {
  factory ObjectElement._internalWrap() => new ObjectElementImpl.internal_();

}
class ObjectElementImpl extends ObjectElement implements js_library.JSObjectInterfacesDom {
  ObjectElementImpl.internal_() : super.internal_();
  get runtimeType => ObjectElement;
  toString() => super.toString();
}
patch class DomMatrix {
  factory DomMatrix._internalWrap() => new DomMatrixImpl.internal_();

}
class DomMatrixImpl extends DomMatrix implements js_library.JSObjectInterfacesDom {
  DomMatrixImpl.internal_() : super.internal_();
  get runtimeType => DomMatrix;
  toString() => super.toString();
}
patch class AbstractWorker {
  factory AbstractWorker._internalWrap() => new AbstractWorkerImpl.internal_();

}
class AbstractWorkerImpl extends AbstractWorker implements js_library.JSObjectInterfacesDom {
  AbstractWorkerImpl.internal_() : super.internal_();
  get runtimeType => AbstractWorker;
  toString() => super.toString();
}
patch class ResourceProgressEvent {
  factory ResourceProgressEvent._internalWrap() => new ResourceProgressEventImpl.internal_();

}
class ResourceProgressEventImpl extends ResourceProgressEvent implements js_library.JSObjectInterfacesDom {
  ResourceProgressEventImpl.internal_() : super.internal_();
  get runtimeType => ResourceProgressEvent;
  toString() => super.toString();
}
patch class ValidityState {
  factory ValidityState._internalWrap() => new ValidityStateImpl.internal_();

}
class ValidityStateImpl extends ValidityState implements js_library.JSObjectInterfacesDom {
  ValidityStateImpl.internal_() : super.internal_();
  get runtimeType => ValidityState;
  toString() => super.toString();
}
patch class HRElement {
  factory HRElement._internalWrap() => new HRElementImpl.internal_();

}
class HRElementImpl extends HRElement implements js_library.JSObjectInterfacesDom {
  HRElementImpl.internal_() : super.internal_();
  get runtimeType => HRElement;
  toString() => super.toString();
}
patch class OptGroupElement {
  factory OptGroupElement._internalWrap() => new OptGroupElementImpl.internal_();

}
class OptGroupElementImpl extends OptGroupElement implements js_library.JSObjectInterfacesDom {
  OptGroupElementImpl.internal_() : super.internal_();
  get runtimeType => OptGroupElement;
  toString() => super.toString();
}
patch class Crypto {
  factory Crypto._internalWrap() => new CryptoImpl.internal_();

}
class CryptoImpl extends Crypto implements js_library.JSObjectInterfacesDom {
  CryptoImpl.internal_() : super.internal_();
  get runtimeType => Crypto;
  toString() => super.toString();
}
patch class PerformanceTiming {
  factory PerformanceTiming._internalWrap() => new PerformanceTimingImpl.internal_();

}
class PerformanceTimingImpl extends PerformanceTiming implements js_library.JSObjectInterfacesDom {
  PerformanceTimingImpl.internal_() : super.internal_();
  get runtimeType => PerformanceTiming;
  toString() => super.toString();
}
patch class RtcDataChannel {
  factory RtcDataChannel._internalWrap() => new RtcDataChannelImpl.internal_();

}
class RtcDataChannelImpl extends RtcDataChannel implements js_library.JSObjectInterfacesDom {
  RtcDataChannelImpl.internal_() : super.internal_();
  get runtimeType => RtcDataChannel;
  toString() => super.toString();
}
patch class NavigatorOnLine {
  factory NavigatorOnLine._internalWrap() => new NavigatorOnLineImpl.internal_();

}
class NavigatorOnLineImpl extends NavigatorOnLine implements js_library.JSObjectInterfacesDom {
  NavigatorOnLineImpl.internal_() : super.internal_();
  get runtimeType => NavigatorOnLine;
  toString() => super.toString();
}
patch class _HTMLAppletElement {
  factory _HTMLAppletElement._internalWrap() => new _HTMLAppletElementImpl.internal_();

}
class _HTMLAppletElementImpl extends _HTMLAppletElement implements js_library.JSObjectInterfacesDom {
  _HTMLAppletElementImpl.internal_() : super.internal_();
  get runtimeType => _HTMLAppletElement;
  toString() => super.toString();
}
patch class SpeechSynthesisVoice {
  factory SpeechSynthesisVoice._internalWrap() => new SpeechSynthesisVoiceImpl.internal_();

}
class SpeechSynthesisVoiceImpl extends SpeechSynthesisVoice implements js_library.JSObjectInterfacesDom {
  SpeechSynthesisVoiceImpl.internal_() : super.internal_();
  get runtimeType => SpeechSynthesisVoice;
  toString() => super.toString();
}
patch class FontFaceSetLoadEvent {
  factory FontFaceSetLoadEvent._internalWrap() => new FontFaceSetLoadEventImpl.internal_();

}
class FontFaceSetLoadEventImpl extends FontFaceSetLoadEvent implements js_library.JSObjectInterfacesDom {
  FontFaceSetLoadEventImpl.internal_() : super.internal_();
  get runtimeType => FontFaceSetLoadEvent;
  toString() => super.toString();
}
patch class NavigatorStorageUtils {
  factory NavigatorStorageUtils._internalWrap() => new NavigatorStorageUtilsImpl.internal_();

}
class NavigatorStorageUtilsImpl extends NavigatorStorageUtils implements js_library.JSObjectInterfacesDom {
  NavigatorStorageUtilsImpl.internal_() : super.internal_();
  get runtimeType => NavigatorStorageUtils;
  toString() => super.toString();
}
patch class SourceElement {
  factory SourceElement._internalWrap() => new SourceElementImpl.internal_();

}
class SourceElementImpl extends SourceElement implements js_library.JSObjectInterfacesDom {
  SourceElementImpl.internal_() : super.internal_();
  get runtimeType => SourceElement;
  toString() => super.toString();
}
patch class InjectedScriptHost {
  factory InjectedScriptHost._internalWrap() => new InjectedScriptHostImpl.internal_();

}
class InjectedScriptHostImpl extends InjectedScriptHost implements js_library.JSObjectInterfacesDom {
  InjectedScriptHostImpl.internal_() : super.internal_();
  get runtimeType => InjectedScriptHost;
  toString() => super.toString();
}
patch class UIEvent {
  factory UIEvent._internalWrap() => new UIEventImpl.internal_();

}
class UIEventImpl extends UIEvent implements js_library.JSObjectInterfacesDom {
  UIEventImpl.internal_() : super.internal_();
  get runtimeType => UIEvent;
  toString() => super.toString();
}
patch class HtmlHtmlElement {
  factory HtmlHtmlElement._internalWrap() => new HtmlHtmlElementImpl.internal_();

}
class HtmlHtmlElementImpl extends HtmlHtmlElement implements js_library.JSObjectInterfacesDom {
  HtmlHtmlElementImpl.internal_() : super.internal_();
  get runtimeType => HtmlHtmlElement;
  toString() => super.toString();
}
patch class ClipboardEvent {
  factory ClipboardEvent._internalWrap() => new ClipboardEventImpl.internal_();

}
class ClipboardEventImpl extends ClipboardEvent implements js_library.JSObjectInterfacesDom {
  ClipboardEventImpl.internal_() : super.internal_();
  get runtimeType => ClipboardEvent;
  toString() => super.toString();
}
patch class OptionElement {
  factory OptionElement._internalWrap() => new OptionElementImpl.internal_();

}
class OptionElementImpl extends OptionElement implements js_library.JSObjectInterfacesDom {
  OptionElementImpl.internal_() : super.internal_();
  get runtimeType => OptionElement;
  toString() => super.toString();
}
patch class MediaSource {
  factory MediaSource._internalWrap() => new MediaSourceImpl.internal_();

}
class MediaSourceImpl extends MediaSource implements js_library.JSObjectInterfacesDom {
  MediaSourceImpl.internal_() : super.internal_();
  get runtimeType => MediaSource;
  toString() => super.toString();
}
patch class MediaKeyMessageEvent {
  factory MediaKeyMessageEvent._internalWrap() => new MediaKeyMessageEventImpl.internal_();

}
class MediaKeyMessageEventImpl extends MediaKeyMessageEvent implements js_library.JSObjectInterfacesDom {
  MediaKeyMessageEventImpl.internal_() : super.internal_();
  get runtimeType => MediaKeyMessageEvent;
  toString() => super.toString();
}
patch class CustomEvent {
  factory CustomEvent._internalWrap() => new CustomEventImpl.internal_();

}
class CustomEventImpl extends CustomEvent implements js_library.JSObjectInterfacesDom {
  CustomEventImpl.internal_() : super.internal_();
  get runtimeType => CustomEvent;
  toString() => super.toString();
}
patch class VttRegion {
  factory VttRegion._internalWrap() => new VttRegionImpl.internal_();

}
class VttRegionImpl extends VttRegion implements js_library.JSObjectInterfacesDom {
  VttRegionImpl.internal_() : super.internal_();
  get runtimeType => VttRegion;
  toString() => super.toString();
}
patch class HeadingElement {
  factory HeadingElement._internalWrap() => new HeadingElementImpl.internal_();

}
class HeadingElementImpl extends HeadingElement implements js_library.JSObjectInterfacesDom {
  HeadingElementImpl.internal_() : super.internal_();
  get runtimeType => HeadingElement;
  toString() => super.toString();
}
patch class History {
  factory History._internalWrap() => new HistoryImpl.internal_();

}
class HistoryImpl extends History implements js_library.JSObjectInterfacesDom {
  HistoryImpl.internal_() : super.internal_();
  get runtimeType => History;
  toString() => super.toString();
}
patch class ServiceWorkerRegistration {
  factory ServiceWorkerRegistration._internalWrap() => new ServiceWorkerRegistrationImpl.internal_();

}
class ServiceWorkerRegistrationImpl extends ServiceWorkerRegistration implements js_library.JSObjectInterfacesDom {
  ServiceWorkerRegistrationImpl.internal_() : super.internal_();
  get runtimeType => ServiceWorkerRegistration;
  toString() => super.toString();
}
patch class _WorkerNavigator {
  factory _WorkerNavigator._internalWrap() => new _WorkerNavigatorImpl.internal_();

}
class _WorkerNavigatorImpl extends _WorkerNavigator implements js_library.JSObjectInterfacesDom {
  _WorkerNavigatorImpl.internal_() : super.internal_();
  get runtimeType => _WorkerNavigator;
  toString() => super.toString();
}
patch class RtcStatsResponse {
  factory RtcStatsResponse._internalWrap() => new RtcStatsResponseImpl.internal_();

}
class RtcStatsResponseImpl extends RtcStatsResponse implements js_library.JSObjectInterfacesDom {
  RtcStatsResponseImpl.internal_() : super.internal_();
  get runtimeType => RtcStatsResponse;
  toString() => super.toString();
}
patch class DirectoryReader {
  factory DirectoryReader._internalWrap() => new DirectoryReaderImpl.internal_();

}
class DirectoryReaderImpl extends DirectoryReader implements js_library.JSObjectInterfacesDom {
  DirectoryReaderImpl.internal_() : super.internal_();
  get runtimeType => DirectoryReader;
  toString() => super.toString();
}
patch class Headers {
  factory Headers._internalWrap() => new HeadersImpl.internal_();

}
class HeadersImpl extends Headers implements js_library.JSObjectInterfacesDom {
  HeadersImpl.internal_() : super.internal_();
  get runtimeType => Headers;
  toString() => super.toString();
}
patch class DataListElement {
  factory DataListElement._internalWrap() => new DataListElementImpl.internal_();

}
class DataListElementImpl extends DataListElement implements js_library.JSObjectInterfacesDom {
  DataListElementImpl.internal_() : super.internal_();
  get runtimeType => DataListElement;
  toString() => super.toString();
}
patch class MediaList {
  factory MediaList._internalWrap() => new MediaListImpl.internal_();

}
class MediaListImpl extends MediaList implements js_library.JSObjectInterfacesDom {
  MediaListImpl.internal_() : super.internal_();
  get runtimeType => MediaList;
  toString() => super.toString();
}
patch class ParentNode {
  factory ParentNode._internalWrap() => new ParentNodeImpl.internal_();

}
class ParentNodeImpl extends ParentNode implements js_library.JSObjectInterfacesDom {
  ParentNodeImpl.internal_() : super.internal_();
  get runtimeType => ParentNode;
  toString() => super.toString();
}
patch class _FileReaderSync {
  factory _FileReaderSync._internalWrap() => new _FileReaderSyncImpl.internal_();

}
class _FileReaderSyncImpl extends _FileReaderSync implements js_library.JSObjectInterfacesDom {
  _FileReaderSyncImpl.internal_() : super.internal_();
  get runtimeType => _FileReaderSync;
  toString() => super.toString();
}
patch class DataTransferItemList {
  factory DataTransferItemList._internalWrap() => new DataTransferItemListImpl.internal_();

}
class DataTransferItemListImpl extends DataTransferItemList implements js_library.JSObjectInterfacesDom {
  DataTransferItemListImpl.internal_() : super.internal_();
  get runtimeType => DataTransferItemList;
  toString() => super.toString();
}
patch class GlobalEventHandlers {
  factory GlobalEventHandlers._internalWrap() => new GlobalEventHandlersImpl.internal_();

}
class GlobalEventHandlersImpl extends GlobalEventHandlers implements js_library.JSObjectInterfacesDom {
  GlobalEventHandlersImpl.internal_() : super.internal_();
  get runtimeType => GlobalEventHandlers;
  toString() => super.toString();
}
patch class DocumentFragment {
  factory DocumentFragment._internalWrap() => new DocumentFragmentImpl.internal_();

}
class DocumentFragmentImpl extends DocumentFragment implements js_library.JSObjectInterfacesDom {
  DocumentFragmentImpl.internal_() : super.internal_();
  get runtimeType => DocumentFragment;
  toString() => super.toString();
}
patch class DomImplementation {
  factory DomImplementation._internalWrap() => new DomImplementationImpl.internal_();

}
class DomImplementationImpl extends DomImplementation implements js_library.JSObjectInterfacesDom {
  DomImplementationImpl.internal_() : super.internal_();
  get runtimeType => DomImplementation;
  toString() => super.toString();
}
patch class PeriodicSyncEvent {
  factory PeriodicSyncEvent._internalWrap() => new PeriodicSyncEventImpl.internal_();

}
class PeriodicSyncEventImpl extends PeriodicSyncEvent implements js_library.JSObjectInterfacesDom {
  PeriodicSyncEventImpl.internal_() : super.internal_();
  get runtimeType => PeriodicSyncEvent;
  toString() => super.toString();
}
patch class DialogElement {
  factory DialogElement._internalWrap() => new DialogElementImpl.internal_();

}
class DialogElementImpl extends DialogElement implements js_library.JSObjectInterfacesDom {
  DialogElementImpl.internal_() : super.internal_();
  get runtimeType => DialogElement;
  toString() => super.toString();
}
patch class PeriodicSyncRegistration {
  factory PeriodicSyncRegistration._internalWrap() => new PeriodicSyncRegistrationImpl.internal_();

}
class PeriodicSyncRegistrationImpl extends PeriodicSyncRegistration implements js_library.JSObjectInterfacesDom {
  PeriodicSyncRegistrationImpl.internal_() : super.internal_();
  get runtimeType => PeriodicSyncRegistration;
  toString() => super.toString();
}
patch class MessagePort {
  factory MessagePort._internalWrap() => new MessagePortImpl.internal_();

}
class MessagePortImpl extends MessagePort implements js_library.JSObjectInterfacesDom {
  MessagePortImpl.internal_() : super.internal_();
  get runtimeType => MessagePort;
  toString() => super.toString();
}
patch class FileReader {
  factory FileReader._internalWrap() => new FileReaderImpl.internal_();

}
class FileReaderImpl extends FileReader implements js_library.JSObjectInterfacesDom {
  FileReaderImpl.internal_() : super.internal_();
  get runtimeType => FileReader;
  toString() => super.toString();
}
patch class HtmlOptionsCollection {
  factory HtmlOptionsCollection._internalWrap() => new HtmlOptionsCollectionImpl.internal_();

}
class HtmlOptionsCollectionImpl extends HtmlOptionsCollection implements js_library.JSObjectInterfacesDom {
  HtmlOptionsCollectionImpl.internal_() : super.internal_();
  get runtimeType => HtmlOptionsCollection;
  toString() => super.toString();
}
patch class _HTMLFrameSetElement {
  factory _HTMLFrameSetElement._internalWrap() => new _HTMLFrameSetElementImpl.internal_();

}
class _HTMLFrameSetElementImpl extends _HTMLFrameSetElement implements js_library.JSObjectInterfacesDom {
  _HTMLFrameSetElementImpl.internal_() : super.internal_();
  get runtimeType => _HTMLFrameSetElement;
  toString() => super.toString();
}
patch class PerformanceMeasure {
  factory PerformanceMeasure._internalWrap() => new PerformanceMeasureImpl.internal_();

}
class PerformanceMeasureImpl extends PerformanceMeasure implements js_library.JSObjectInterfacesDom {
  PerformanceMeasureImpl.internal_() : super.internal_();
  get runtimeType => PerformanceMeasure;
  toString() => super.toString();
}
patch class ServiceWorkerContainer {
  factory ServiceWorkerContainer._internalWrap() => new ServiceWorkerContainerImpl.internal_();

}
class ServiceWorkerContainerImpl extends ServiceWorkerContainer implements js_library.JSObjectInterfacesDom {
  ServiceWorkerContainerImpl.internal_() : super.internal_();
  get runtimeType => ServiceWorkerContainer;
  toString() => super.toString();
}
patch class TrackDefaultList {
  factory TrackDefaultList._internalWrap() => new TrackDefaultListImpl.internal_();

}
class TrackDefaultListImpl extends TrackDefaultList implements js_library.JSObjectInterfacesDom {
  TrackDefaultListImpl.internal_() : super.internal_();
  get runtimeType => TrackDefaultList;
  toString() => super.toString();
}
patch class RelatedEvent {
  factory RelatedEvent._internalWrap() => new RelatedEventImpl.internal_();

}
class RelatedEventImpl extends RelatedEvent implements js_library.JSObjectInterfacesDom {
  RelatedEventImpl.internal_() : super.internal_();
  get runtimeType => RelatedEvent;
  toString() => super.toString();
}
patch class TableCaptionElement {
  factory TableCaptionElement._internalWrap() => new TableCaptionElementImpl.internal_();

}
class TableCaptionElementImpl extends TableCaptionElement implements js_library.JSObjectInterfacesDom {
  TableCaptionElementImpl.internal_() : super.internal_();
  get runtimeType => TableCaptionElement;
  toString() => super.toString();
}
patch class ScrollState {
  factory ScrollState._internalWrap() => new ScrollStateImpl.internal_();

}
class ScrollStateImpl extends ScrollState implements js_library.JSObjectInterfacesDom {
  ScrollStateImpl.internal_() : super.internal_();
  get runtimeType => ScrollState;
  toString() => super.toString();
}
patch class MenuItemElement {
  factory MenuItemElement._internalWrap() => new MenuItemElementImpl.internal_();

}
class MenuItemElementImpl extends MenuItemElement implements js_library.JSObjectInterfacesDom {
  MenuItemElementImpl.internal_() : super.internal_();
  get runtimeType => MenuItemElement;
  toString() => super.toString();
}
patch class MediaKeyStatusMap {
  factory MediaKeyStatusMap._internalWrap() => new MediaKeyStatusMapImpl.internal_();

}
class MediaKeyStatusMapImpl extends MediaKeyStatusMap implements js_library.JSObjectInterfacesDom {
  MediaKeyStatusMapImpl.internal_() : super.internal_();
  get runtimeType => MediaKeyStatusMap;
  toString() => super.toString();
}
patch class RtcDataChannelEvent {
  factory RtcDataChannelEvent._internalWrap() => new RtcDataChannelEventImpl.internal_();

}
class RtcDataChannelEventImpl extends RtcDataChannelEvent implements js_library.JSObjectInterfacesDom {
  RtcDataChannelEventImpl.internal_() : super.internal_();
  get runtimeType => RtcDataChannelEvent;
  toString() => super.toString();
}
patch class MediaElement {
  factory MediaElement._internalWrap() => new MediaElementImpl.internal_();

}
class MediaElementImpl extends MediaElement implements js_library.JSObjectInterfacesDom {
  MediaElementImpl.internal_() : super.internal_();
  get runtimeType => MediaElement;
  toString() => super.toString();
}
patch class MediaDeviceInfo {
  factory MediaDeviceInfo._internalWrap() => new MediaDeviceInfoImpl.internal_();

}
class MediaDeviceInfoImpl extends MediaDeviceInfo implements js_library.JSObjectInterfacesDom {
  MediaDeviceInfoImpl.internal_() : super.internal_();
  get runtimeType => MediaDeviceInfo;
  toString() => super.toString();
}
patch class StorageEvent {
  factory StorageEvent._internalWrap() => new StorageEventImpl.internal_();

}
class StorageEventImpl extends StorageEvent implements js_library.JSObjectInterfacesDom {
  StorageEventImpl.internal_() : super.internal_();
  get runtimeType => StorageEvent;
  toString() => super.toString();
}
patch class FormData {
  factory FormData._internalWrap() => new FormDataImpl.internal_();

}
class FormDataImpl extends FormData implements js_library.JSObjectInterfacesDom {
  FormDataImpl.internal_() : super.internal_();
  get runtimeType => FormData;
  toString() => super.toString();
}
patch class PushEvent {
  factory PushEvent._internalWrap() => new PushEventImpl.internal_();

}
class PushEventImpl extends PushEvent implements js_library.JSObjectInterfacesDom {
  PushEventImpl.internal_() : super.internal_();
  get runtimeType => PushEvent;
  toString() => super.toString();
}
patch class CssPageRule {
  factory CssPageRule._internalWrap() => new CssPageRuleImpl.internal_();

}
class CssPageRuleImpl extends CssPageRule implements js_library.JSObjectInterfacesDom {
  CssPageRuleImpl.internal_() : super.internal_();
  get runtimeType => CssPageRule;
  toString() => super.toString();
}
patch class PageTransitionEvent {
  factory PageTransitionEvent._internalWrap() => new PageTransitionEventImpl.internal_();

}
class PageTransitionEventImpl extends PageTransitionEvent implements js_library.JSObjectInterfacesDom {
  PageTransitionEventImpl.internal_() : super.internal_();
  get runtimeType => PageTransitionEvent;
  toString() => super.toString();
}
patch class MemoryInfo {
  factory MemoryInfo._internalWrap() => new MemoryInfoImpl.internal_();

}
class MemoryInfoImpl extends MemoryInfo implements js_library.JSObjectInterfacesDom {
  MemoryInfoImpl.internal_() : super.internal_();
  get runtimeType => MemoryInfo;
  toString() => super.toString();
}
patch class ChromiumValuebuffer {
  factory ChromiumValuebuffer._internalWrap() => new ChromiumValuebufferImpl.internal_();

}
class ChromiumValuebufferImpl extends ChromiumValuebuffer implements js_library.JSObjectInterfacesDom {
  ChromiumValuebufferImpl.internal_() : super.internal_();
  get runtimeType => ChromiumValuebuffer;
  toString() => super.toString();
}
patch class KeyframeEffect {
  factory KeyframeEffect._internalWrap() => new KeyframeEffectImpl.internal_();

}
class KeyframeEffectImpl extends KeyframeEffect implements js_library.JSObjectInterfacesDom {
  KeyframeEffectImpl.internal_() : super.internal_();
  get runtimeType => KeyframeEffect;
  toString() => super.toString();
}
patch class XPathEvaluator {
  factory XPathEvaluator._internalWrap() => new XPathEvaluatorImpl.internal_();

}
class XPathEvaluatorImpl extends XPathEvaluator implements js_library.JSObjectInterfacesDom {
  XPathEvaluatorImpl.internal_() : super.internal_();
  get runtimeType => XPathEvaluator;
  toString() => super.toString();
}
patch class ContentElement {
  factory ContentElement._internalWrap() => new ContentElementImpl.internal_();

}
class ContentElementImpl extends ContentElement implements js_library.JSObjectInterfacesDom {
  ContentElementImpl.internal_() : super.internal_();
  get runtimeType => ContentElement;
  toString() => super.toString();
}
patch class CompositionEvent {
  factory CompositionEvent._internalWrap() => new CompositionEventImpl.internal_();

}
class CompositionEventImpl extends CompositionEvent implements js_library.JSObjectInterfacesDom {
  CompositionEventImpl.internal_() : super.internal_();
  get runtimeType => CompositionEvent;
  toString() => super.toString();
}
patch class FileWriter {
  factory FileWriter._internalWrap() => new FileWriterImpl.internal_();

}
class FileWriterImpl extends FileWriter implements js_library.JSObjectInterfacesDom {
  FileWriterImpl.internal_() : super.internal_();
  get runtimeType => FileWriter;
  toString() => super.toString();
}
patch class SpanElement {
  factory SpanElement._internalWrap() => new SpanElementImpl.internal_();

}
class SpanElementImpl extends SpanElement implements js_library.JSObjectInterfacesDom {
  SpanElementImpl.internal_() : super.internal_();
  get runtimeType => SpanElement;
  toString() => super.toString();
}
patch class _WebKitCSSMatrix {
  factory _WebKitCSSMatrix._internalWrap() => new _WebKitCSSMatrixImpl.internal_();

}
class _WebKitCSSMatrixImpl extends _WebKitCSSMatrix implements js_library.JSObjectInterfacesDom {
  _WebKitCSSMatrixImpl.internal_() : super.internal_();
  get runtimeType => _WebKitCSSMatrix;
  toString() => super.toString();
}
patch class WorkerPerformance {
  factory WorkerPerformance._internalWrap() => new WorkerPerformanceImpl.internal_();

}
class WorkerPerformanceImpl extends WorkerPerformance implements js_library.JSObjectInterfacesDom {
  WorkerPerformanceImpl.internal_() : super.internal_();
  get runtimeType => WorkerPerformance;
  toString() => super.toString();
}
patch class TransitionEvent {
  factory TransitionEvent._internalWrap() => new TransitionEventImpl.internal_();

}
class TransitionEventImpl extends TransitionEvent implements js_library.JSObjectInterfacesDom {
  TransitionEventImpl.internal_() : super.internal_();
  get runtimeType => TransitionEvent;
  toString() => super.toString();
}
patch class GamepadEvent {
  factory GamepadEvent._internalWrap() => new GamepadEventImpl.internal_();

}
class GamepadEventImpl extends GamepadEvent implements js_library.JSObjectInterfacesDom {
  GamepadEventImpl.internal_() : super.internal_();
  get runtimeType => GamepadEvent;
  toString() => super.toString();
}
patch class _HTMLFontElement {
  factory _HTMLFontElement._internalWrap() => new _HTMLFontElementImpl.internal_();

}
class _HTMLFontElementImpl extends _HTMLFontElement implements js_library.JSObjectInterfacesDom {
  _HTMLFontElementImpl.internal_() : super.internal_();
  get runtimeType => _HTMLFontElement;
  toString() => super.toString();
}
patch class _Response {
  factory _Response._internalWrap() => new _ResponseImpl.internal_();

}
class _ResponseImpl extends _Response implements js_library.JSObjectInterfacesDom {
  _ResponseImpl.internal_() : super.internal_();
  get runtimeType => _Response;
  toString() => super.toString();
}
patch class _PagePopupController {
  factory _PagePopupController._internalWrap() => new _PagePopupControllerImpl.internal_();

}
class _PagePopupControllerImpl extends _PagePopupController implements js_library.JSObjectInterfacesDom {
  _PagePopupControllerImpl.internal_() : super.internal_();
  get runtimeType => _PagePopupController;
  toString() => super.toString();
}
patch class AnimationPlayerEvent {
  factory AnimationPlayerEvent._internalWrap() => new AnimationPlayerEventImpl.internal_();

}
class AnimationPlayerEventImpl extends AnimationPlayerEvent implements js_library.JSObjectInterfacesDom {
  AnimationPlayerEventImpl.internal_() : super.internal_();
  get runtimeType => AnimationPlayerEvent;
  toString() => super.toString();
}
patch class DomTokenList {
  factory DomTokenList._internalWrap() => new DomTokenListImpl.internal_();

}
class DomTokenListImpl extends DomTokenList implements js_library.JSObjectInterfacesDom {
  DomTokenListImpl.internal_() : super.internal_();
  get runtimeType => DomTokenList;
  toString() => super.toString();
}
patch class _GamepadList {
  factory _GamepadList._internalWrap() => new _GamepadListImpl.internal_();

}
class _GamepadListImpl extends _GamepadList implements js_library.JSObjectInterfacesDom {
  _GamepadListImpl.internal_() : super.internal_();
  get runtimeType => _GamepadList;
  toString() => super.toString();
}
patch class PluginArray {
  factory PluginArray._internalWrap() => new PluginArrayImpl.internal_();

}
class PluginArrayImpl extends PluginArray implements js_library.JSObjectInterfacesDom {
  PluginArrayImpl.internal_() : super.internal_();
  get runtimeType => PluginArray;
  toString() => super.toString();
}
patch class DomPoint {
  factory DomPoint._internalWrap() => new DomPointImpl.internal_();

}
class DomPointImpl extends DomPoint implements js_library.JSObjectInterfacesDom {
  DomPointImpl.internal_() : super.internal_();
  get runtimeType => DomPoint;
  toString() => super.toString();
}
patch class FileSystem {
  factory FileSystem._internalWrap() => new FileSystemImpl.internal_();

}
class FileSystemImpl extends FileSystem implements js_library.JSObjectInterfacesDom {
  FileSystemImpl.internal_() : super.internal_();
  get runtimeType => FileSystem;
  toString() => super.toString();
}
patch class NavigatorCpu {
  factory NavigatorCpu._internalWrap() => new NavigatorCpuImpl.internal_();

}
class NavigatorCpuImpl extends NavigatorCpu implements js_library.JSObjectInterfacesDom {
  NavigatorCpuImpl.internal_() : super.internal_();
  get runtimeType => NavigatorCpu;
  toString() => super.toString();
}
patch class VideoTrack {
  factory VideoTrack._internalWrap() => new VideoTrackImpl.internal_();

}
class VideoTrackImpl extends VideoTrack implements js_library.JSObjectInterfacesDom {
  VideoTrackImpl.internal_() : super.internal_();
  get runtimeType => VideoTrack;
  toString() => super.toString();
}
patch class QuoteElement {
  factory QuoteElement._internalWrap() => new QuoteElementImpl.internal_();

}
class QuoteElementImpl extends QuoteElement implements js_library.JSObjectInterfacesDom {
  QuoteElementImpl.internal_() : super.internal_();
  get runtimeType => QuoteElement;
  toString() => super.toString();
}
patch class LabelElement {
  factory LabelElement._internalWrap() => new LabelElementImpl.internal_();

}
class LabelElementImpl extends LabelElement implements js_library.JSObjectInterfacesDom {
  LabelElementImpl.internal_() : super.internal_();
  get runtimeType => LabelElement;
  toString() => super.toString();
}
patch class TextAreaElement {
  factory TextAreaElement._internalWrap() => new TextAreaElementImpl.internal_();

}
class TextAreaElementImpl extends TextAreaElement implements js_library.JSObjectInterfacesDom {
  TextAreaElementImpl.internal_() : super.internal_();
  get runtimeType => TextAreaElement;
  toString() => super.toString();
}
patch class TextMetrics {
  factory TextMetrics._internalWrap() => new TextMetricsImpl.internal_();

}
class TextMetricsImpl extends TextMetrics implements js_library.JSObjectInterfacesDom {
  TextMetricsImpl.internal_() : super.internal_();
  get runtimeType => TextMetrics;
  toString() => super.toString();
}
patch class Selection {
  factory Selection._internalWrap() => new SelectionImpl.internal_();

}
class SelectionImpl extends Selection implements js_library.JSObjectInterfacesDom {
  SelectionImpl.internal_() : super.internal_();
  get runtimeType => Selection;
  toString() => super.toString();
}
patch class NodeIterator {
  factory NodeIterator._internalWrap() => new NodeIteratorImpl.internal_();

}
class NodeIteratorImpl extends NodeIterator implements js_library.JSObjectInterfacesDom {
  NodeIteratorImpl.internal_() : super.internal_();
  get runtimeType => NodeIterator;
  toString() => super.toString();
}
patch class _HTMLDirectoryElement {
  factory _HTMLDirectoryElement._internalWrap() => new _HTMLDirectoryElementImpl.internal_();

}
class _HTMLDirectoryElementImpl extends _HTMLDirectoryElement implements js_library.JSObjectInterfacesDom {
  _HTMLDirectoryElementImpl.internal_() : super.internal_();
  get runtimeType => _HTMLDirectoryElement;
  toString() => super.toString();
}
patch class AreaElement {
  factory AreaElement._internalWrap() => new AreaElementImpl.internal_();

}
class AreaElementImpl extends AreaElement implements js_library.JSObjectInterfacesDom {
  AreaElementImpl.internal_() : super.internal_();
  get runtimeType => AreaElement;
  toString() => super.toString();
}
patch class Notification {
  factory Notification._internalWrap() => new NotificationImpl.internal_();

}
class NotificationImpl extends Notification implements js_library.JSObjectInterfacesDom {
  NotificationImpl.internal_() : super.internal_();
  get runtimeType => Notification;
  toString() => super.toString();
}
patch class TableCellElement {
  factory TableCellElement._internalWrap() => new TableCellElementImpl.internal_();

}
class TableCellElementImpl extends TableCellElement implements js_library.JSObjectInterfacesDom {
  TableCellElementImpl.internal_() : super.internal_();
  get runtimeType => TableCellElement;
  toString() => super.toString();
}
patch class DomStringMap {
  factory DomStringMap._internalWrap() => new DomStringMapImpl.internal_();

}
class DomStringMapImpl extends DomStringMap implements js_library.JSObjectInterfacesDom {
  DomStringMapImpl.internal_() : super.internal_();
  get runtimeType => DomStringMap;
  toString() => super.toString();
}
patch class Entry {
  factory Entry._internalWrap() => new EntryImpl.internal_();

}
class EntryImpl extends Entry implements js_library.JSObjectInterfacesDom {
  EntryImpl.internal_() : super.internal_();
  get runtimeType => Entry;
  toString() => super.toString();
}
patch class PeriodicSyncManager {
  factory PeriodicSyncManager._internalWrap() => new PeriodicSyncManagerImpl.internal_();

}
class PeriodicSyncManagerImpl extends PeriodicSyncManager implements js_library.JSObjectInterfacesDom {
  PeriodicSyncManagerImpl.internal_() : super.internal_();
  get runtimeType => PeriodicSyncManager;
  toString() => super.toString();
}
patch class RtcIceCandidate {
  factory RtcIceCandidate._internalWrap() => new RtcIceCandidateImpl.internal_();

}
class RtcIceCandidateImpl extends RtcIceCandidate implements js_library.JSObjectInterfacesDom {
  RtcIceCandidateImpl.internal_() : super.internal_();
  get runtimeType => RtcIceCandidate;
  toString() => super.toString();
}
patch class SpeechRecognitionResult {
  factory SpeechRecognitionResult._internalWrap() => new SpeechRecognitionResultImpl.internal_();

}
class SpeechRecognitionResultImpl extends SpeechRecognitionResult implements js_library.JSObjectInterfacesDom {
  SpeechRecognitionResultImpl.internal_() : super.internal_();
  get runtimeType => SpeechRecognitionResult;
  toString() => super.toString();
}
patch class TextTrackList {
  factory TextTrackList._internalWrap() => new TextTrackListImpl.internal_();

}
class TextTrackListImpl extends TextTrackList implements js_library.JSObjectInterfacesDom {
  TextTrackListImpl.internal_() : super.internal_();
  get runtimeType => TextTrackList;
  toString() => super.toString();
}
patch class _ServiceWorker {
  factory _ServiceWorker._internalWrap() => new _ServiceWorkerImpl.internal_();

}
class _ServiceWorkerImpl extends _ServiceWorker implements js_library.JSObjectInterfacesDom {
  _ServiceWorkerImpl.internal_() : super.internal_();
  get runtimeType => _ServiceWorker;
  toString() => super.toString();
}
patch class SharedWorker {
  factory SharedWorker._internalWrap() => new SharedWorkerImpl.internal_();

}
class SharedWorkerImpl extends SharedWorker implements js_library.JSObjectInterfacesDom {
  SharedWorkerImpl.internal_() : super.internal_();
  get runtimeType => SharedWorker;
  toString() => super.toString();
}
patch class EventTarget {
  factory EventTarget._internalWrap() => new EventTargetImpl.internal_();

}
class EventTargetImpl extends EventTarget implements js_library.JSObjectInterfacesDom {
  EventTargetImpl.internal_() : super.internal_();
  get runtimeType => EventTarget;
  toString() => super.toString();
}
patch class HtmlFormControlsCollection {
  factory HtmlFormControlsCollection._internalWrap() => new HtmlFormControlsCollectionImpl.internal_();

}
class HtmlFormControlsCollectionImpl extends HtmlFormControlsCollection implements js_library.JSObjectInterfacesDom {
  HtmlFormControlsCollectionImpl.internal_() : super.internal_();
  get runtimeType => HtmlFormControlsCollection;
  toString() => super.toString();
}
patch class KeyboardEvent {
  factory KeyboardEvent._internalWrap() => new KeyboardEventImpl.internal_();

}
class KeyboardEventImpl extends KeyboardEvent implements js_library.JSObjectInterfacesDom {
  KeyboardEventImpl.internal_() : super.internal_();
  get runtimeType => KeyboardEvent;
  toString() => super.toString();
}
patch class MidiMessageEvent {
  factory MidiMessageEvent._internalWrap() => new MidiMessageEventImpl.internal_();

}
class MidiMessageEventImpl extends MidiMessageEvent implements js_library.JSObjectInterfacesDom {
  MidiMessageEventImpl.internal_() : super.internal_();
  get runtimeType => MidiMessageEvent;
  toString() => super.toString();
}
patch class CacheStorage {
  factory CacheStorage._internalWrap() => new CacheStorageImpl.internal_();

}
class CacheStorageImpl extends CacheStorage implements js_library.JSObjectInterfacesDom {
  CacheStorageImpl.internal_() : super.internal_();
  get runtimeType => CacheStorage;
  toString() => super.toString();
}
patch class CanvasElement {
  factory CanvasElement._internalWrap() => new CanvasElementImpl.internal_();

}
class CanvasElementImpl extends CanvasElement implements js_library.JSObjectInterfacesDom {
  CanvasElementImpl.internal_() : super.internal_();
  get runtimeType => CanvasElement;
  toString() => super.toString();
}
patch class BatteryManager {
  factory BatteryManager._internalWrap() => new BatteryManagerImpl.internal_();

}
class BatteryManagerImpl extends BatteryManager implements js_library.JSObjectInterfacesDom {
  BatteryManagerImpl.internal_() : super.internal_();
  get runtimeType => BatteryManager;
  toString() => super.toString();
}
patch class _StyleSheetList {
  factory _StyleSheetList._internalWrap() => new _StyleSheetListImpl.internal_();

}
class _StyleSheetListImpl extends _StyleSheetList implements js_library.JSObjectInterfacesDom {
  _StyleSheetListImpl.internal_() : super.internal_();
  get runtimeType => _StyleSheetList;
  toString() => super.toString();
}
patch class Path2D {
  factory Path2D._internalWrap() => new Path2DImpl.internal_();

}
class Path2DImpl extends Path2D implements js_library.JSObjectInterfacesDom {
  Path2DImpl.internal_() : super.internal_();
  get runtimeType => Path2D;
  toString() => super.toString();
}
patch class DeviceRotationRate {
  factory DeviceRotationRate._internalWrap() => new DeviceRotationRateImpl.internal_();

}
class DeviceRotationRateImpl extends DeviceRotationRate implements js_library.JSObjectInterfacesDom {
  DeviceRotationRateImpl.internal_() : super.internal_();
  get runtimeType => DeviceRotationRate;
  toString() => super.toString();
}
patch class Screen {
  factory Screen._internalWrap() => new ScreenImpl.internal_();

}
class ScreenImpl extends Screen implements js_library.JSObjectInterfacesDom {
  ScreenImpl.internal_() : super.internal_();
  get runtimeType => Screen;
  toString() => super.toString();
}
patch class StorageInfo {
  factory StorageInfo._internalWrap() => new StorageInfoImpl.internal_();

}
class StorageInfoImpl extends StorageInfo implements js_library.JSObjectInterfacesDom {
  StorageInfoImpl.internal_() : super.internal_();
  get runtimeType => StorageInfo;
  toString() => super.toString();
}
patch class TableColElement {
  factory TableColElement._internalWrap() => new TableColElementImpl.internal_();

}
class TableColElementImpl extends TableColElement implements js_library.JSObjectInterfacesDom {
  TableColElementImpl.internal_() : super.internal_();
  get runtimeType => TableColElement;
  toString() => super.toString();
}
patch class CssStyleDeclaration {
  factory CssStyleDeclaration._internalWrap() => new CssStyleDeclarationImpl.internal_();

}
class CssStyleDeclarationImpl extends CssStyleDeclaration implements js_library.JSObjectInterfacesDom {
  CssStyleDeclarationImpl.internal_() : super.internal_();
  get runtimeType => CssStyleDeclaration;
  toString() => super.toString();
}
patch class DomStringList {
  factory DomStringList._internalWrap() => new DomStringListImpl.internal_();

}
class DomStringListImpl extends DomStringList implements js_library.JSObjectInterfacesDom {
  DomStringListImpl.internal_() : super.internal_();
  get runtimeType => DomStringList;
  toString() => super.toString();
}
patch class StashedPortCollection {
  factory StashedPortCollection._internalWrap() => new StashedPortCollectionImpl.internal_();

}
class StashedPortCollectionImpl extends StashedPortCollection implements js_library.JSObjectInterfacesDom {
  StashedPortCollectionImpl.internal_() : super.internal_();
  get runtimeType => StashedPortCollection;
  toString() => super.toString();
}
patch class SyncManager {
  factory SyncManager._internalWrap() => new SyncManagerImpl.internal_();

}
class SyncManagerImpl extends SyncManager implements js_library.JSObjectInterfacesDom {
  SyncManagerImpl.internal_() : super.internal_();
  get runtimeType => SyncManager;
  toString() => super.toString();
}
patch class HttpRequestUpload {
  factory HttpRequestUpload._internalWrap() => new HttpRequestUploadImpl.internal_();

}
class HttpRequestUploadImpl extends HttpRequestUpload implements js_library.JSObjectInterfacesDom {
  HttpRequestUploadImpl.internal_() : super.internal_();
  get runtimeType => HttpRequestUpload;
  toString() => super.toString();
}
patch class ReadableStreamReader {
  factory ReadableStreamReader._internalWrap() => new ReadableStreamReaderImpl.internal_();

}
class ReadableStreamReaderImpl extends ReadableStreamReader implements js_library.JSObjectInterfacesDom {
  ReadableStreamReaderImpl.internal_() : super.internal_();
  get runtimeType => ReadableStreamReader;
  toString() => super.toString();
}
patch class MediaKeySession {
  factory MediaKeySession._internalWrap() => new MediaKeySessionImpl.internal_();

}
class MediaKeySessionImpl extends MediaKeySession implements js_library.JSObjectInterfacesDom {
  MediaKeySessionImpl.internal_() : super.internal_();
  get runtimeType => MediaKeySession;
  toString() => super.toString();
}
patch class Gamepad {
  factory Gamepad._internalWrap() => new GamepadImpl.internal_();

}
class GamepadImpl extends Gamepad implements js_library.JSObjectInterfacesDom {
  GamepadImpl.internal_() : super.internal_();
  get runtimeType => Gamepad;
  toString() => super.toString();
}
patch class Worker {
  factory Worker._internalWrap() => new WorkerImpl.internal_();

}
class WorkerImpl extends Worker implements js_library.JSObjectInterfacesDom {
  WorkerImpl.internal_() : super.internal_();
  get runtimeType => Worker;
  toString() => super.toString();
}
patch class DefaultSessionStartEvent {
  factory DefaultSessionStartEvent._internalWrap() => new DefaultSessionStartEventImpl.internal_();

}
class DefaultSessionStartEventImpl extends DefaultSessionStartEvent implements js_library.JSObjectInterfacesDom {
  DefaultSessionStartEventImpl.internal_() : super.internal_();
  get runtimeType => DefaultSessionStartEvent;
  toString() => super.toString();
}
patch class DListElement {
  factory DListElement._internalWrap() => new DListElementImpl.internal_();

}
class DListElementImpl extends DListElement implements js_library.JSObjectInterfacesDom {
  DListElementImpl.internal_() : super.internal_();
  get runtimeType => DListElement;
  toString() => super.toString();
}
patch class FileError {
  factory FileError._internalWrap() => new FileErrorImpl.internal_();

}
class FileErrorImpl extends FileError implements js_library.JSObjectInterfacesDom {
  FileErrorImpl.internal_() : super.internal_();
  get runtimeType => FileError;
  toString() => super.toString();
}
patch class HeadElement {
  factory HeadElement._internalWrap() => new HeadElementImpl.internal_();

}
class HeadElementImpl extends HeadElement implements js_library.JSObjectInterfacesDom {
  HeadElementImpl.internal_() : super.internal_();
  get runtimeType => HeadElement;
  toString() => super.toString();
}
patch class BluetoothGattCharacteristic {
  factory BluetoothGattCharacteristic._internalWrap() => new BluetoothGattCharacteristicImpl.internal_();

}
class BluetoothGattCharacteristicImpl extends BluetoothGattCharacteristic implements js_library.JSObjectInterfacesDom {
  BluetoothGattCharacteristicImpl.internal_() : super.internal_();
  get runtimeType => BluetoothGattCharacteristic;
  toString() => super.toString();
}
patch class DomSettableTokenList {
  factory DomSettableTokenList._internalWrap() => new DomSettableTokenListImpl.internal_();

}
class DomSettableTokenListImpl extends DomSettableTokenList implements js_library.JSObjectInterfacesDom {
  DomSettableTokenListImpl.internal_() : super.internal_();
  get runtimeType => DomSettableTokenList;
  toString() => super.toString();
}
patch class _WorkerLocation {
  factory _WorkerLocation._internalWrap() => new _WorkerLocationImpl.internal_();

}
class _WorkerLocationImpl extends _WorkerLocation implements js_library.JSObjectInterfacesDom {
  _WorkerLocationImpl.internal_() : super.internal_();
  get runtimeType => _WorkerLocation;
  toString() => super.toString();
}
patch class TouchList {
  factory TouchList._internalWrap() => new TouchListImpl.internal_();

}
class TouchListImpl extends TouchList implements js_library.JSObjectInterfacesDom {
  TouchListImpl.internal_() : super.internal_();
  get runtimeType => TouchList;
  toString() => super.toString();
}
patch class MetaElement {
  factory MetaElement._internalWrap() => new MetaElementImpl.internal_();

}
class MetaElementImpl extends MetaElement implements js_library.JSObjectInterfacesDom {
  MetaElementImpl.internal_() : super.internal_();
  get runtimeType => MetaElement;
  toString() => super.toString();
}
patch class TrackElement {
  factory TrackElement._internalWrap() => new TrackElementImpl.internal_();

}
class TrackElementImpl extends TrackElement implements js_library.JSObjectInterfacesDom {
  TrackElementImpl.internal_() : super.internal_();
  get runtimeType => TrackElement;
  toString() => super.toString();
}
patch class WheelEvent {
  factory WheelEvent._internalWrap() => new WheelEventImpl.internal_();

}
class WheelEventImpl extends WheelEvent implements js_library.JSObjectInterfacesDom {
  WheelEventImpl.internal_() : super.internal_();
  get runtimeType => WheelEvent;
  toString() => super.toString();
}
patch class DomMatrixReadOnly {
  factory DomMatrixReadOnly._internalWrap() => new DomMatrixReadOnlyImpl.internal_();

}
class DomMatrixReadOnlyImpl extends DomMatrixReadOnly implements js_library.JSObjectInterfacesDom {
  DomMatrixReadOnlyImpl.internal_() : super.internal_();
  get runtimeType => DomMatrixReadOnly;
  toString() => super.toString();
}
patch class FormElement {
  factory FormElement._internalWrap() => new FormElementImpl.internal_();

}
class FormElementImpl extends FormElement implements js_library.JSObjectInterfacesDom {
  FormElementImpl.internal_() : super.internal_();
  get runtimeType => FormElement;
  toString() => super.toString();
}
patch class _SpeechRecognitionResultList {
  factory _SpeechRecognitionResultList._internalWrap() => new _SpeechRecognitionResultListImpl.internal_();

}
class _SpeechRecognitionResultListImpl extends _SpeechRecognitionResultList implements js_library.JSObjectInterfacesDom {
  _SpeechRecognitionResultListImpl.internal_() : super.internal_();
  get runtimeType => _SpeechRecognitionResultList;
  toString() => super.toString();
}
patch class CompositorWorkerGlobalScope {
  factory CompositorWorkerGlobalScope._internalWrap() => new CompositorWorkerGlobalScopeImpl.internal_();

}
class CompositorWorkerGlobalScopeImpl extends CompositorWorkerGlobalScope implements js_library.JSObjectInterfacesDom {
  CompositorWorkerGlobalScopeImpl.internal_() : super.internal_();
  get runtimeType => CompositorWorkerGlobalScope;
  toString() => super.toString();
}
patch class PresentationAvailability {
  factory PresentationAvailability._internalWrap() => new PresentationAvailabilityImpl.internal_();

}
class PresentationAvailabilityImpl extends PresentationAvailability implements js_library.JSObjectInterfacesDom {
  PresentationAvailabilityImpl.internal_() : super.internal_();
  get runtimeType => PresentationAvailability;
  toString() => super.toString();
}
patch class FontFaceSet {
  factory FontFaceSet._internalWrap() => new FontFaceSetImpl.internal_();

}
class FontFaceSetImpl extends FontFaceSet implements js_library.JSObjectInterfacesDom {
  FontFaceSetImpl.internal_() : super.internal_();
  get runtimeType => FontFaceSet;
  toString() => super.toString();
}
patch class _SubtleCrypto {
  factory _SubtleCrypto._internalWrap() => new _SubtleCryptoImpl.internal_();

}
class _SubtleCryptoImpl extends _SubtleCrypto implements js_library.JSObjectInterfacesDom {
  _SubtleCryptoImpl.internal_() : super.internal_();
  get runtimeType => _SubtleCrypto;
  toString() => super.toString();
}
patch class ButtonElement {
  factory ButtonElement._internalWrap() => new ButtonElementImpl.internal_();

}
class ButtonElementImpl extends ButtonElement implements js_library.JSObjectInterfacesDom {
  ButtonElementImpl.internal_() : super.internal_();
  get runtimeType => ButtonElement;
  toString() => super.toString();
}
patch class ProcessingInstruction {
  factory ProcessingInstruction._internalWrap() => new ProcessingInstructionImpl.internal_();

}
class ProcessingInstructionImpl extends ProcessingInstruction implements js_library.JSObjectInterfacesDom {
  ProcessingInstructionImpl.internal_() : super.internal_();
  get runtimeType => ProcessingInstruction;
  toString() => super.toString();
}
patch class StashedMessagePort {
  factory StashedMessagePort._internalWrap() => new StashedMessagePortImpl.internal_();

}
class StashedMessagePortImpl extends StashedMessagePort implements js_library.JSObjectInterfacesDom {
  StashedMessagePortImpl.internal_() : super.internal_();
  get runtimeType => StashedMessagePort;
  toString() => super.toString();
}
patch class DeviceAcceleration {
  factory DeviceAcceleration._internalWrap() => new DeviceAccelerationImpl.internal_();

}
class DeviceAccelerationImpl extends DeviceAcceleration implements js_library.JSObjectInterfacesDom {
  DeviceAccelerationImpl.internal_() : super.internal_();
  get runtimeType => DeviceAcceleration;
  toString() => super.toString();
}
patch class MapElement {
  factory MapElement._internalWrap() => new MapElementImpl.internal_();

}
class MapElementImpl extends MapElement implements js_library.JSObjectInterfacesDom {
  MapElementImpl.internal_() : super.internal_();
  get runtimeType => MapElement;
  toString() => super.toString();
}
patch class PresentationSession {
  factory PresentationSession._internalWrap() => new PresentationSessionImpl.internal_();

}
class PresentationSessionImpl extends PresentationSession implements js_library.JSObjectInterfacesDom {
  PresentationSessionImpl.internal_() : super.internal_();
  get runtimeType => PresentationSession;
  toString() => super.toString();
}
patch class RtcDtmfToneChangeEvent {
  factory RtcDtmfToneChangeEvent._internalWrap() => new RtcDtmfToneChangeEventImpl.internal_();

}
class RtcDtmfToneChangeEventImpl extends RtcDtmfToneChangeEvent implements js_library.JSObjectInterfacesDom {
  RtcDtmfToneChangeEventImpl.internal_() : super.internal_();
  get runtimeType => RtcDtmfToneChangeEvent;
  toString() => super.toString();
}
patch class PerformanceCompositeTiming {
  factory PerformanceCompositeTiming._internalWrap() => new PerformanceCompositeTimingImpl.internal_();

}
class PerformanceCompositeTimingImpl extends PerformanceCompositeTiming implements js_library.JSObjectInterfacesDom {
  PerformanceCompositeTimingImpl.internal_() : super.internal_();
  get runtimeType => PerformanceCompositeTiming;
  toString() => super.toString();
}
patch class NodeFilter {
  factory NodeFilter._internalWrap() => new NodeFilterImpl.internal_();

}
class NodeFilterImpl extends NodeFilter implements js_library.JSObjectInterfacesDom {
  NodeFilterImpl.internal_() : super.internal_();
  get runtimeType => NodeFilter;
  toString() => super.toString();
}
patch class _DomRect {
  factory _DomRect._internalWrap() => new _DomRectImpl.internal_();

}
class _DomRectImpl extends _DomRect implements js_library.JSObjectInterfacesDom {
  _DomRectImpl.internal_() : super.internal_();
  get runtimeType => _DomRect;
  toString() => super.toString();
}
patch class PermissionStatus {
  factory PermissionStatus._internalWrap() => new PermissionStatusImpl.internal_();

}
class PermissionStatusImpl extends PermissionStatus implements js_library.JSObjectInterfacesDom {
  PermissionStatusImpl.internal_() : super.internal_();
  get runtimeType => PermissionStatus;
  toString() => super.toString();
}
patch class DeviceMotionEvent {
  factory DeviceMotionEvent._internalWrap() => new DeviceMotionEventImpl.internal_();

}
class DeviceMotionEventImpl extends DeviceMotionEvent implements js_library.JSObjectInterfacesDom {
  DeviceMotionEventImpl.internal_() : super.internal_();
  get runtimeType => DeviceMotionEvent;
  toString() => super.toString();
}
patch class Comment {
  factory Comment._internalWrap() => new CommentImpl.internal_();

}
class CommentImpl extends Comment implements js_library.JSObjectInterfacesDom {
  CommentImpl.internal_() : super.internal_();
  get runtimeType => Comment;
  toString() => super.toString();
}
patch class CanvasPattern {
  factory CanvasPattern._internalWrap() => new CanvasPatternImpl.internal_();

}
class CanvasPatternImpl extends CanvasPattern implements js_library.JSObjectInterfacesDom {
  CanvasPatternImpl.internal_() : super.internal_();
  get runtimeType => CanvasPattern;
  toString() => super.toString();
}
patch class CompositorProxy {
  factory CompositorProxy._internalWrap() => new CompositorProxyImpl.internal_();

}
class CompositorProxyImpl extends CompositorProxy implements js_library.JSObjectInterfacesDom {
  CompositorProxyImpl.internal_() : super.internal_();
  get runtimeType => CompositorProxy;
  toString() => super.toString();
}
patch class MediaKeyError {
  factory MediaKeyError._internalWrap() => new MediaKeyErrorImpl.internal_();

}
class MediaKeyErrorImpl extends MediaKeyError implements js_library.JSObjectInterfacesDom {
  MediaKeyErrorImpl.internal_() : super.internal_();
  get runtimeType => MediaKeyError;
  toString() => super.toString();
}
patch class CssRule {
  factory CssRule._internalWrap() => new CssRuleImpl.internal_();

}
class CssRuleImpl extends CssRule implements js_library.JSObjectInterfacesDom {
  CssRuleImpl.internal_() : super.internal_();
  get runtimeType => CssRule;
  toString() => super.toString();
}
patch class SpeechRecognitionAlternative {
  factory SpeechRecognitionAlternative._internalWrap() => new SpeechRecognitionAlternativeImpl.internal_();

}
class SpeechRecognitionAlternativeImpl extends SpeechRecognitionAlternative implements js_library.JSObjectInterfacesDom {
  SpeechRecognitionAlternativeImpl.internal_() : super.internal_();
  get runtimeType => SpeechRecognitionAlternative;
  toString() => super.toString();
}
patch class XPathExpression {
  factory XPathExpression._internalWrap() => new XPathExpressionImpl.internal_();

}
class XPathExpressionImpl extends XPathExpression implements js_library.JSObjectInterfacesDom {
  XPathExpressionImpl.internal_() : super.internal_();
  get runtimeType => XPathExpression;
  toString() => super.toString();
}
patch class Permissions {
  factory Permissions._internalWrap() => new PermissionsImpl.internal_();

}
class PermissionsImpl extends Permissions implements js_library.JSObjectInterfacesDom {
  PermissionsImpl.internal_() : super.internal_();
  get runtimeType => Permissions;
  toString() => super.toString();
}
patch class PerformanceNavigation {
  factory PerformanceNavigation._internalWrap() => new PerformanceNavigationImpl.internal_();

}
class PerformanceNavigationImpl extends PerformanceNavigation implements js_library.JSObjectInterfacesDom {
  PerformanceNavigationImpl.internal_() : super.internal_();
  get runtimeType => PerformanceNavigation;
  toString() => super.toString();
}
patch class SecurityPolicyViolationEvent {
  factory SecurityPolicyViolationEvent._internalWrap() => new SecurityPolicyViolationEventImpl.internal_();

}
class SecurityPolicyViolationEventImpl extends SecurityPolicyViolationEvent implements js_library.JSObjectInterfacesDom {
  SecurityPolicyViolationEventImpl.internal_() : super.internal_();
  get runtimeType => SecurityPolicyViolationEvent;
  toString() => super.toString();
}
patch class TableElement {
  factory TableElement._internalWrap() => new TableElementImpl.internal_();

}
class TableElementImpl extends TableElement implements js_library.JSObjectInterfacesDom {
  TableElementImpl.internal_() : super.internal_();
  get runtimeType => TableElement;
  toString() => super.toString();
}
patch class NavigatorID {
  factory NavigatorID._internalWrap() => new NavigatorIDImpl.internal_();

}
class NavigatorIDImpl extends NavigatorID implements js_library.JSObjectInterfacesDom {
  NavigatorIDImpl.internal_() : super.internal_();
  get runtimeType => NavigatorID;
  toString() => super.toString();
}
patch class ServicePort {
  factory ServicePort._internalWrap() => new ServicePortImpl.internal_();

}
class ServicePortImpl extends ServicePort implements js_library.JSObjectInterfacesDom {
  ServicePortImpl.internal_() : super.internal_();
  get runtimeType => ServicePort;
  toString() => super.toString();
}
patch class TextTrackCue {
  factory TextTrackCue._internalWrap() => new TextTrackCueImpl.internal_();

}
class TextTrackCueImpl extends TextTrackCue implements js_library.JSObjectInterfacesDom {
  TextTrackCueImpl.internal_() : super.internal_();
  get runtimeType => TextTrackCue;
  toString() => super.toString();
}
patch class FileEntry {
  factory FileEntry._internalWrap() => new FileEntryImpl.internal_();

}
class FileEntryImpl extends FileEntry implements js_library.JSObjectInterfacesDom {
  FileEntryImpl.internal_() : super.internal_();
  get runtimeType => FileEntry;
  toString() => super.toString();
}
patch class _DOMFileSystemSync {
  factory _DOMFileSystemSync._internalWrap() => new _DOMFileSystemSyncImpl.internal_();

}
class _DOMFileSystemSyncImpl extends _DOMFileSystemSync implements js_library.JSObjectInterfacesDom {
  _DOMFileSystemSyncImpl.internal_() : super.internal_();
  get runtimeType => _DOMFileSystemSync;
  toString() => super.toString();
}
patch class Animation {
  factory Animation._internalWrap() => new AnimationImpl.internal_();

}
class AnimationImpl extends Animation implements js_library.JSObjectInterfacesDom {
  AnimationImpl.internal_() : super.internal_();
  get runtimeType => Animation;
  toString() => super.toString();
}
patch class Navigator {
  factory Navigator._internalWrap() => new NavigatorImpl.internal_();

}
class NavigatorImpl extends Navigator implements js_library.JSObjectInterfacesDom {
  NavigatorImpl.internal_() : super.internal_();
  get runtimeType => Navigator;
  toString() => super.toString();
}
patch class MediaQueryList {
  factory MediaQueryList._internalWrap() => new MediaQueryListImpl.internal_();

}
class MediaQueryListImpl extends MediaQueryList implements js_library.JSObjectInterfacesDom {
  MediaQueryListImpl.internal_() : super.internal_();
  get runtimeType => MediaQueryList;
  toString() => super.toString();
}
patch class CssImportRule {
  factory CssImportRule._internalWrap() => new CssImportRuleImpl.internal_();

}
class CssImportRuleImpl extends CssImportRule implements js_library.JSObjectInterfacesDom {
  CssImportRuleImpl.internal_() : super.internal_();
  get runtimeType => CssImportRule;
  toString() => super.toString();
}
patch class StorageQuota {
  factory StorageQuota._internalWrap() => new StorageQuotaImpl.internal_();

}
class StorageQuotaImpl extends StorageQuota implements js_library.JSObjectInterfacesDom {
  StorageQuotaImpl.internal_() : super.internal_();
  get runtimeType => StorageQuota;
  toString() => super.toString();
}
patch class MediaQueryListEvent {
  factory MediaQueryListEvent._internalWrap() => new MediaQueryListEventImpl.internal_();

}
class MediaQueryListEventImpl extends MediaQueryListEvent implements js_library.JSObjectInterfacesDom {
  MediaQueryListEventImpl.internal_() : super.internal_();
  get runtimeType => MediaQueryListEvent;
  toString() => super.toString();
}
patch class BluetoothGattRemoteServer {
  factory BluetoothGattRemoteServer._internalWrap() => new BluetoothGattRemoteServerImpl.internal_();

}
class BluetoothGattRemoteServerImpl extends BluetoothGattRemoteServer implements js_library.JSObjectInterfacesDom {
  BluetoothGattRemoteServerImpl.internal_() : super.internal_();
  get runtimeType => BluetoothGattRemoteServer;
  toString() => super.toString();
}
patch class FileList {
  factory FileList._internalWrap() => new FileListImpl.internal_();

}
class FileListImpl extends FileList implements js_library.JSObjectInterfacesDom {
  FileListImpl.internal_() : super.internal_();
  get runtimeType => FileList;
  toString() => super.toString();
}
patch class WindowClient {
  factory WindowClient._internalWrap() => new WindowClientImpl.internal_();

}
class WindowClientImpl extends WindowClient implements js_library.JSObjectInterfacesDom {
  WindowClientImpl.internal_() : super.internal_();
  get runtimeType => WindowClient;
  toString() => super.toString();
}
patch class ReadableStream {
  factory ReadableStream._internalWrap() => new ReadableStreamImpl.internal_();

}
class ReadableStreamImpl extends ReadableStream implements js_library.JSObjectInterfacesDom {
  ReadableStreamImpl.internal_() : super.internal_();
  get runtimeType => ReadableStream;
  toString() => super.toString();
}
patch class Node {
  factory Node._internalWrap() => new NodeImpl.internal_();

}
class NodeImpl extends Node implements js_library.JSObjectInterfacesDom {
  NodeImpl.internal_() : super.internal_();
  get runtimeType => Node;
  toString() => super.toString();
}
patch class DedicatedWorkerGlobalScope {
  factory DedicatedWorkerGlobalScope._internalWrap() => new DedicatedWorkerGlobalScopeImpl.internal_();

}
class DedicatedWorkerGlobalScopeImpl extends DedicatedWorkerGlobalScope implements js_library.JSObjectInterfacesDom {
  DedicatedWorkerGlobalScopeImpl.internal_() : super.internal_();
  get runtimeType => DedicatedWorkerGlobalScope;
  toString() => super.toString();
}
patch class AudioTrackList {
  factory AudioTrackList._internalWrap() => new AudioTrackListImpl.internal_();

}
class AudioTrackListImpl extends AudioTrackList implements js_library.JSObjectInterfacesDom {
  AudioTrackListImpl.internal_() : super.internal_();
  get runtimeType => AudioTrackList;
  toString() => super.toString();
}
patch class StyleMedia {
  factory StyleMedia._internalWrap() => new StyleMediaImpl.internal_();

}
class StyleMediaImpl extends StyleMedia implements js_library.JSObjectInterfacesDom {
  StyleMediaImpl.internal_() : super.internal_();
  get runtimeType => StyleMedia;
  toString() => super.toString();
}
patch class WindowEventHandlers {
  factory WindowEventHandlers._internalWrap() => new WindowEventHandlersImpl.internal_();

}
class WindowEventHandlersImpl extends WindowEventHandlers implements js_library.JSObjectInterfacesDom {
  WindowEventHandlersImpl.internal_() : super.internal_();
  get runtimeType => WindowEventHandlers;
  toString() => super.toString();
}
patch class SourceInfo {
  factory SourceInfo._internalWrap() => new SourceInfoImpl.internal_();

}
class SourceInfoImpl extends SourceInfo implements js_library.JSObjectInterfacesDom {
  SourceInfoImpl.internal_() : super.internal_();
  get runtimeType => SourceInfo;
  toString() => super.toString();
}
patch class _DirectoryEntrySync {
  factory _DirectoryEntrySync._internalWrap() => new _DirectoryEntrySyncImpl.internal_();

}
class _DirectoryEntrySyncImpl extends _DirectoryEntrySync implements js_library.JSObjectInterfacesDom {
  _DirectoryEntrySyncImpl.internal_() : super.internal_();
  get runtimeType => _DirectoryEntrySync;
  toString() => super.toString();
}
patch class AnimationEvent {
  factory AnimationEvent._internalWrap() => new AnimationEventImpl.internal_();

}
class AnimationEventImpl extends AnimationEvent implements js_library.JSObjectInterfacesDom {
  AnimationEventImpl.internal_() : super.internal_();
  get runtimeType => AnimationEvent;
  toString() => super.toString();
}
patch class PluginPlaceholderElement {
  factory PluginPlaceholderElement._internalWrap() => new PluginPlaceholderElementImpl.internal_();

}
class PluginPlaceholderElementImpl extends PluginPlaceholderElement implements js_library.JSObjectInterfacesDom {
  PluginPlaceholderElementImpl.internal_() : super.internal_();
  get runtimeType => PluginPlaceholderElement;
  toString() => super.toString();
}
patch class _MutationEvent {
  factory _MutationEvent._internalWrap() => new _MutationEventImpl.internal_();

}
class _MutationEventImpl extends _MutationEvent implements js_library.JSObjectInterfacesDom {
  _MutationEventImpl.internal_() : super.internal_();
  get runtimeType => _MutationEvent;
  toString() => super.toString();
}
patch class LinkElement {
  factory LinkElement._internalWrap() => new LinkElementImpl.internal_();

}
class LinkElementImpl extends LinkElement implements js_library.JSObjectInterfacesDom {
  LinkElementImpl.internal_() : super.internal_();
  get runtimeType => LinkElement;
  toString() => super.toString();
}
patch class TextTrackCueList {
  factory TextTrackCueList._internalWrap() => new TextTrackCueListImpl.internal_();

}
class TextTrackCueListImpl extends TextTrackCueList implements js_library.JSObjectInterfacesDom {
  TextTrackCueListImpl.internal_() : super.internal_();
  get runtimeType => TextTrackCueList;
  toString() => super.toString();
}
patch class VideoPlaybackQuality {
  factory VideoPlaybackQuality._internalWrap() => new VideoPlaybackQualityImpl.internal_();

}
class VideoPlaybackQualityImpl extends VideoPlaybackQuality implements js_library.JSObjectInterfacesDom {
  VideoPlaybackQualityImpl.internal_() : super.internal_();
  get runtimeType => VideoPlaybackQuality;
  toString() => super.toString();
}
patch class IFrameElement {
  factory IFrameElement._internalWrap() => new IFrameElementImpl.internal_();

}
class IFrameElementImpl extends IFrameElement implements js_library.JSObjectInterfacesDom {
  IFrameElementImpl.internal_() : super.internal_();
  get runtimeType => IFrameElement;
  toString() => super.toString();
}
patch class FontFace {
  factory FontFace._internalWrap() => new FontFaceImpl.internal_();

}
class FontFaceImpl extends FontFace implements js_library.JSObjectInterfacesDom {
  FontFaceImpl.internal_() : super.internal_();
  get runtimeType => FontFace;
  toString() => super.toString();
}
patch class AnchorElement {
  factory AnchorElement._internalWrap() => new AnchorElementImpl.internal_();

}
class AnchorElementImpl extends AnchorElement implements js_library.JSObjectInterfacesDom {
  AnchorElementImpl.internal_() : super.internal_();
  get runtimeType => AnchorElement;
  toString() => super.toString();
}
patch class XsltProcessor {
  factory XsltProcessor._internalWrap() => new XsltProcessorImpl.internal_();

}
class XsltProcessorImpl extends XsltProcessor implements js_library.JSObjectInterfacesDom {
  XsltProcessorImpl.internal_() : super.internal_();
  get runtimeType => XsltProcessor;
  toString() => super.toString();
}
patch class NavigatorLanguage {
  factory NavigatorLanguage._internalWrap() => new NavigatorLanguageImpl.internal_();

}
class NavigatorLanguageImpl extends NavigatorLanguage implements js_library.JSObjectInterfacesDom {
  NavigatorLanguageImpl.internal_() : super.internal_();
  get runtimeType => NavigatorLanguage;
  toString() => super.toString();
}
patch class ParagraphElement {
  factory ParagraphElement._internalWrap() => new ParagraphElementImpl.internal_();

}
class ParagraphElementImpl extends ParagraphElement implements js_library.JSObjectInterfacesDom {
  ParagraphElementImpl.internal_() : super.internal_();
  get runtimeType => ParagraphElement;
  toString() => super.toString();
}
patch class HmdvrDevice {
  factory HmdvrDevice._internalWrap() => new HmdvrDeviceImpl.internal_();

}
class HmdvrDeviceImpl extends HmdvrDevice implements js_library.JSObjectInterfacesDom {
  HmdvrDeviceImpl.internal_() : super.internal_();
  get runtimeType => HmdvrDevice;
  toString() => super.toString();
}
patch class SourceBuffer {
  factory SourceBuffer._internalWrap() => new SourceBufferImpl.internal_();

}
class SourceBufferImpl extends SourceBuffer implements js_library.JSObjectInterfacesDom {
  SourceBufferImpl.internal_() : super.internal_();
  get runtimeType => SourceBuffer;
  toString() => super.toString();
}
patch class CssCharsetRule {
  factory CssCharsetRule._internalWrap() => new CssCharsetRuleImpl.internal_();

}
class CssCharsetRuleImpl extends CssCharsetRule implements js_library.JSObjectInterfacesDom {
  CssCharsetRuleImpl.internal_() : super.internal_();
  get runtimeType => CssCharsetRule;
  toString() => super.toString();
}
patch class DeprecatedStorageQuota {
  factory DeprecatedStorageQuota._internalWrap() => new DeprecatedStorageQuotaImpl.internal_();

}
class DeprecatedStorageQuotaImpl extends DeprecatedStorageQuota implements js_library.JSObjectInterfacesDom {
  DeprecatedStorageQuotaImpl.internal_() : super.internal_();
  get runtimeType => DeprecatedStorageQuota;
  toString() => super.toString();
}
patch class DataTransfer {
  factory DataTransfer._internalWrap() => new DataTransferImpl.internal_();

}
class DataTransferImpl extends DataTransfer implements js_library.JSObjectInterfacesDom {
  DataTransferImpl.internal_() : super.internal_();
  get runtimeType => DataTransfer;
  toString() => super.toString();
}
patch class MutationObserver {
  factory MutationObserver._internalWrap() => new MutationObserverImpl.internal_();

}
class MutationObserverImpl extends MutationObserver implements js_library.JSObjectInterfacesDom {
  MutationObserverImpl.internal_() : super.internal_();
  get runtimeType => MutationObserver;
  toString() => super.toString();
}
patch class XmlSerializer {
  factory XmlSerializer._internalWrap() => new XmlSerializerImpl.internal_();

}
class XmlSerializerImpl extends XmlSerializer implements js_library.JSObjectInterfacesDom {
  XmlSerializerImpl.internal_() : super.internal_();
  get runtimeType => XmlSerializer;
  toString() => super.toString();
}
patch class PictureElement {
  factory PictureElement._internalWrap() => new PictureElementImpl.internal_();

}
class PictureElementImpl extends PictureElement implements js_library.JSObjectInterfacesDom {
  PictureElementImpl.internal_() : super.internal_();
  get runtimeType => PictureElement;
  toString() => super.toString();
}
patch class MediaEncryptedEvent {
  factory MediaEncryptedEvent._internalWrap() => new MediaEncryptedEventImpl.internal_();

}
class MediaEncryptedEventImpl extends MediaEncryptedEvent implements js_library.JSObjectInterfacesDom {
  MediaEncryptedEventImpl.internal_() : super.internal_();
  get runtimeType => MediaEncryptedEvent;
  toString() => super.toString();
}
patch class TouchEvent {
  factory TouchEvent._internalWrap() => new TouchEventImpl.internal_();

}
class TouchEventImpl extends TouchEvent implements js_library.JSObjectInterfacesDom {
  TouchEventImpl.internal_() : super.internal_();
  get runtimeType => TouchEvent;
  toString() => super.toString();
}
patch class ServiceWorkerMessageEvent {
  factory ServiceWorkerMessageEvent._internalWrap() => new ServiceWorkerMessageEventImpl.internal_();

}
class ServiceWorkerMessageEventImpl extends ServiceWorkerMessageEvent implements js_library.JSObjectInterfacesDom {
  ServiceWorkerMessageEventImpl.internal_() : super.internal_();
  get runtimeType => ServiceWorkerMessageEvent;
  toString() => super.toString();
}
patch class MeterElement {
  factory MeterElement._internalWrap() => new MeterElementImpl.internal_();

}
class MeterElementImpl extends MeterElement implements js_library.JSObjectInterfacesDom {
  MeterElementImpl.internal_() : super.internal_();
  get runtimeType => MeterElement;
  toString() => super.toString();
}
patch class CssGroupingRule {
  factory CssGroupingRule._internalWrap() => new CssGroupingRuleImpl.internal_();

}
class CssGroupingRuleImpl extends CssGroupingRule implements js_library.JSObjectInterfacesDom {
  CssGroupingRuleImpl.internal_() : super.internal_();
  get runtimeType => CssGroupingRule;
  toString() => super.toString();
}
patch class UListElement {
  factory UListElement._internalWrap() => new UListElementImpl.internal_();

}
class UListElementImpl extends UListElement implements js_library.JSObjectInterfacesDom {
  UListElementImpl.internal_() : super.internal_();
  get runtimeType => UListElement;
  toString() => super.toString();
}
patch class Storage {
  factory Storage._internalWrap() => new StorageImpl.internal_();

}
class StorageImpl extends Storage implements js_library.JSObjectInterfacesDom {
  StorageImpl.internal_() : super.internal_();
  get runtimeType => Storage;
  toString() => super.toString();
}
patch class _DocumentType {
  factory _DocumentType._internalWrap() => new _DocumentTypeImpl.internal_();

}
class _DocumentTypeImpl extends _DocumentType implements js_library.JSObjectInterfacesDom {
  _DocumentTypeImpl.internal_() : super.internal_();
  get runtimeType => _DocumentType;
  toString() => super.toString();
}
patch class ErrorEvent {
  factory ErrorEvent._internalWrap() => new ErrorEventImpl.internal_();

}
class ErrorEventImpl extends ErrorEvent implements js_library.JSObjectInterfacesDom {
  ErrorEventImpl.internal_() : super.internal_();
  get runtimeType => ErrorEvent;
  toString() => super.toString();
}
patch class BodyElement {
  factory BodyElement._internalWrap() => new BodyElementImpl.internal_();

}
class BodyElementImpl extends BodyElement implements js_library.JSObjectInterfacesDom {
  BodyElementImpl.internal_() : super.internal_();
  get runtimeType => BodyElement;
  toString() => super.toString();
}
patch class DeprecatedStorageInfo {
  factory DeprecatedStorageInfo._internalWrap() => new DeprecatedStorageInfoImpl.internal_();

}
class DeprecatedStorageInfoImpl extends DeprecatedStorageInfo implements js_library.JSObjectInterfacesDom {
  DeprecatedStorageInfoImpl.internal_() : super.internal_();
  get runtimeType => DeprecatedStorageInfo;
  toString() => super.toString();
}
patch class Geoposition {
  factory Geoposition._internalWrap() => new GeopositionImpl.internal_();

}
class GeopositionImpl extends Geoposition implements js_library.JSObjectInterfacesDom {
  GeopositionImpl.internal_() : super.internal_();
  get runtimeType => Geoposition;
  toString() => super.toString();
}
patch class ApplicationCacheErrorEvent {
  factory ApplicationCacheErrorEvent._internalWrap() => new ApplicationCacheErrorEventImpl.internal_();

}
class ApplicationCacheErrorEventImpl extends ApplicationCacheErrorEvent implements js_library.JSObjectInterfacesDom {
  ApplicationCacheErrorEventImpl.internal_() : super.internal_();
  get runtimeType => ApplicationCacheErrorEvent;
  toString() => super.toString();
}
patch class MutationRecord {
  factory MutationRecord._internalWrap() => new MutationRecordImpl.internal_();

}
class MutationRecordImpl extends MutationRecord implements js_library.JSObjectInterfacesDom {
  MutationRecordImpl.internal_() : super.internal_();
  get runtimeType => MutationRecord;
  toString() => super.toString();
}
patch class FieldSetElement {
  factory FieldSetElement._internalWrap() => new FieldSetElementImpl.internal_();

}
class FieldSetElementImpl extends FieldSetElement implements js_library.JSObjectInterfacesDom {
  FieldSetElementImpl.internal_() : super.internal_();
  get runtimeType => FieldSetElement;
  toString() => super.toString();
}
patch class NonDocumentTypeChildNode {
  factory NonDocumentTypeChildNode._internalWrap() => new NonDocumentTypeChildNodeImpl.internal_();

}
class NonDocumentTypeChildNodeImpl extends NonDocumentTypeChildNode implements js_library.JSObjectInterfacesDom {
  NonDocumentTypeChildNodeImpl.internal_() : super.internal_();
  get runtimeType => NonDocumentTypeChildNode;
  toString() => super.toString();
}
patch class _DirectoryReaderSync {
  factory _DirectoryReaderSync._internalWrap() => new _DirectoryReaderSyncImpl.internal_();

}
class _DirectoryReaderSyncImpl extends _DirectoryReaderSync implements js_library.JSObjectInterfacesDom {
  _DirectoryReaderSyncImpl.internal_() : super.internal_();
  get runtimeType => _DirectoryReaderSync;
  toString() => super.toString();
}
patch class RtcSessionDescription {
  factory RtcSessionDescription._internalWrap() => new RtcSessionDescriptionImpl.internal_();

}
class RtcSessionDescriptionImpl extends RtcSessionDescription implements js_library.JSObjectInterfacesDom {
  RtcSessionDescriptionImpl.internal_() : super.internal_();
  get runtimeType => RtcSessionDescription;
  toString() => super.toString();
}
patch class PositionSensorVRDevice {
  factory PositionSensorVRDevice._internalWrap() => new PositionSensorVRDeviceImpl.internal_();

}
class PositionSensorVRDeviceImpl extends PositionSensorVRDevice implements js_library.JSObjectInterfacesDom {
  PositionSensorVRDeviceImpl.internal_() : super.internal_();
  get runtimeType => PositionSensorVRDevice;
  toString() => super.toString();
}
patch class Text {
  factory Text._internalWrap() => new TextImpl.internal_();

}
class TextImpl extends Text implements js_library.JSObjectInterfacesDom {
  TextImpl.internal_() : super.internal_();
  get runtimeType => Text;
  toString() => super.toString();
}
patch class AnimationEffectTiming {
  factory AnimationEffectTiming._internalWrap() => new AnimationEffectTimingImpl.internal_();

}
class AnimationEffectTimingImpl extends AnimationEffectTiming implements js_library.JSObjectInterfacesDom {
  AnimationEffectTimingImpl.internal_() : super.internal_();
  get runtimeType => AnimationEffectTiming;
  toString() => super.toString();
}
patch class PositionError {
  factory PositionError._internalWrap() => new PositionErrorImpl.internal_();

}
class PositionErrorImpl extends PositionError implements js_library.JSObjectInterfacesDom {
  PositionErrorImpl.internal_() : super.internal_();
  get runtimeType => PositionError;
  toString() => super.toString();
}
patch class VideoTrackList {
  factory VideoTrackList._internalWrap() => new VideoTrackListImpl.internal_();

}
class VideoTrackListImpl extends VideoTrackList implements js_library.JSObjectInterfacesDom {
  VideoTrackListImpl.internal_() : super.internal_();
  get runtimeType => VideoTrackList;
  toString() => super.toString();
}
patch class GamepadButton {
  factory GamepadButton._internalWrap() => new GamepadButtonImpl.internal_();

}
class GamepadButtonImpl extends GamepadButton implements js_library.JSObjectInterfacesDom {
  GamepadButtonImpl.internal_() : super.internal_();
  get runtimeType => GamepadButton;
  toString() => super.toString();
}
patch class WorkerConsole {
  factory WorkerConsole._internalWrap() => new WorkerConsoleImpl.internal_();

}
class WorkerConsoleImpl extends WorkerConsole implements js_library.JSObjectInterfacesDom {
  WorkerConsoleImpl.internal_() : super.internal_();
  get runtimeType => WorkerConsole;
  toString() => super.toString();
}
patch class TrackDefault {
  factory TrackDefault._internalWrap() => new TrackDefaultImpl.internal_();

}
class TrackDefaultImpl extends TrackDefault implements js_library.JSObjectInterfacesDom {
  TrackDefaultImpl.internal_() : super.internal_();
  get runtimeType => TrackDefault;
  toString() => super.toString();
}
patch class FileStream {
  factory FileStream._internalWrap() => new FileStreamImpl.internal_();

}
class FileStreamImpl extends FileStream implements js_library.JSObjectInterfacesDom {
  FileStreamImpl.internal_() : super.internal_();
  get runtimeType => FileStream;
  toString() => super.toString();
}
patch class _ClientRect {
  factory _ClientRect._internalWrap() => new _ClientRectImpl.internal_();

}
class _ClientRectImpl extends _ClientRect implements js_library.JSObjectInterfacesDom {
  _ClientRectImpl.internal_() : super.internal_();
  get runtimeType => _ClientRect;
  toString() => super.toString();
}
patch class TemplateElement {
  factory TemplateElement._internalWrap() => new TemplateElementImpl.internal_();

}
class TemplateElementImpl extends TemplateElement implements js_library.JSObjectInterfacesDom {
  TemplateElementImpl.internal_() : super.internal_();
  get runtimeType => TemplateElement;
  toString() => super.toString();
}
patch class RtcStatsReport {
  factory RtcStatsReport._internalWrap() => new RtcStatsReportImpl.internal_();

}
class RtcStatsReportImpl extends RtcStatsReport implements js_library.JSObjectInterfacesDom {
  RtcStatsReportImpl.internal_() : super.internal_();
  get runtimeType => RtcStatsReport;
  toString() => super.toString();
}
patch class TimeRanges {
  factory TimeRanges._internalWrap() => new TimeRangesImpl.internal_();

}
class TimeRangesImpl extends TimeRanges implements js_library.JSObjectInterfacesDom {
  TimeRangesImpl.internal_() : super.internal_();
  get runtimeType => TimeRanges;
  toString() => super.toString();
}
patch class _Request {
  factory _Request._internalWrap() => new _RequestImpl.internal_();

}
class _RequestImpl extends _Request implements js_library.JSObjectInterfacesDom {
  _RequestImpl.internal_() : super.internal_();
  get runtimeType => _Request;
  toString() => super.toString();
}
patch class _WindowTimers {
  factory _WindowTimers._internalWrap() => new _WindowTimersImpl.internal_();

}
class _WindowTimersImpl extends _WindowTimers implements js_library.JSObjectInterfacesDom {
  _WindowTimersImpl.internal_() : super.internal_();
  get runtimeType => _WindowTimers;
  toString() => super.toString();
}
patch class VttRegionList {
  factory VttRegionList._internalWrap() => new VttRegionListImpl.internal_();

}
class VttRegionListImpl extends VttRegionList implements js_library.JSObjectInterfacesDom {
  VttRegionListImpl.internal_() : super.internal_();
  get runtimeType => VttRegionList;
  toString() => super.toString();
}
patch class AnimationTimeline {
  factory AnimationTimeline._internalWrap() => new AnimationTimelineImpl.internal_();

}
class AnimationTimelineImpl extends AnimationTimeline implements js_library.JSObjectInterfacesDom {
  AnimationTimelineImpl.internal_() : super.internal_();
  get runtimeType => AnimationTimeline;
  toString() => super.toString();
}
patch class Event {
  factory Event._internalWrap() => new EventImpl.internal_();

}
class EventImpl extends Event implements js_library.JSObjectInterfacesDom {
  EventImpl.internal_() : super.internal_();
  get runtimeType => Event;
  toString() => super.toString();
}
patch class DomIterator {
  factory DomIterator._internalWrap() => new DomIteratorImpl.internal_();

}
class DomIteratorImpl extends DomIterator implements js_library.JSObjectInterfacesDom {
  DomIteratorImpl.internal_() : super.internal_();
  get runtimeType => DomIterator;
  toString() => super.toString();
}
patch class ImageData {
  factory ImageData._internalWrap() => new ImageDataImpl.internal_();

}
class ImageDataImpl extends ImageData implements js_library.JSObjectInterfacesDom {
  ImageDataImpl.internal_() : super.internal_();
  get runtimeType => ImageData;
  toString() => super.toString();
}
patch class MediaStreamTrackEvent {
  factory MediaStreamTrackEvent._internalWrap() => new MediaStreamTrackEventImpl.internal_();

}
class MediaStreamTrackEventImpl extends MediaStreamTrackEvent implements js_library.JSObjectInterfacesDom {
  MediaStreamTrackEventImpl.internal_() : super.internal_();
  get runtimeType => MediaStreamTrackEvent;
  toString() => super.toString();
}
patch class PromiseRejectionEvent {
  factory PromiseRejectionEvent._internalWrap() => new PromiseRejectionEventImpl.internal_();

}
class PromiseRejectionEventImpl extends PromiseRejectionEvent implements js_library.JSObjectInterfacesDom {
  PromiseRejectionEventImpl.internal_() : super.internal_();
  get runtimeType => PromiseRejectionEvent;
  toString() => super.toString();
}
patch class HtmlElement {
  factory HtmlElement._internalWrap() => new HtmlElementImpl.internal_();

}
class HtmlElementImpl extends HtmlElement implements js_library.JSObjectInterfacesDom {
  HtmlElementImpl.internal_() : super.internal_();
  get runtimeType => HtmlElement;
  toString() => super.toString();
}
patch class HtmlDocument {
  factory HtmlDocument._internalWrap() => new HtmlDocumentImpl.internal_();

}
class HtmlDocumentImpl extends HtmlDocument implements js_library.JSObjectInterfacesDom {
  HtmlDocumentImpl.internal_() : super.internal_();
  get runtimeType => HtmlDocument;
  toString() => super.toString();
}
patch class MidiPort {
  factory MidiPort._internalWrap() => new MidiPortImpl.internal_();

}
class MidiPortImpl extends MidiPort implements js_library.JSObjectInterfacesDom {
  MidiPortImpl.internal_() : super.internal_();
  get runtimeType => MidiPort;
  toString() => super.toString();
}
patch class CssMediaRule {
  factory CssMediaRule._internalWrap() => new CssMediaRuleImpl.internal_();

}
class CssMediaRuleImpl extends CssMediaRule implements js_library.JSObjectInterfacesDom {
  CssMediaRuleImpl.internal_() : super.internal_();
  get runtimeType => CssMediaRule;
  toString() => super.toString();
}
patch class CssViewportRule {
  factory CssViewportRule._internalWrap() => new CssViewportRuleImpl.internal_();

}
class CssViewportRuleImpl extends CssViewportRule implements js_library.JSObjectInterfacesDom {
  CssViewportRuleImpl.internal_() : super.internal_();
  get runtimeType => CssViewportRule;
  toString() => super.toString();
}
patch class FederatedCredential {
  factory FederatedCredential._internalWrap() => new FederatedCredentialImpl.internal_();

}
class FederatedCredentialImpl extends FederatedCredential implements js_library.JSObjectInterfacesDom {
  FederatedCredentialImpl.internal_() : super.internal_();
  get runtimeType => FederatedCredential;
  toString() => super.toString();
}
patch class RtcIceCandidateEvent {
  factory RtcIceCandidateEvent._internalWrap() => new RtcIceCandidateEventImpl.internal_();

}
class RtcIceCandidateEventImpl extends RtcIceCandidateEvent implements js_library.JSObjectInterfacesDom {
  RtcIceCandidateEventImpl.internal_() : super.internal_();
  get runtimeType => RtcIceCandidateEvent;
  toString() => super.toString();
}
patch class PerformanceMark {
  factory PerformanceMark._internalWrap() => new PerformanceMarkImpl.internal_();

}
class PerformanceMarkImpl extends PerformanceMark implements js_library.JSObjectInterfacesDom {
  PerformanceMarkImpl.internal_() : super.internal_();
  get runtimeType => PerformanceMark;
  toString() => super.toString();
}
patch class SharedWorkerGlobalScope {
  factory SharedWorkerGlobalScope._internalWrap() => new SharedWorkerGlobalScopeImpl.internal_();

}
class SharedWorkerGlobalScopeImpl extends SharedWorkerGlobalScope implements js_library.JSObjectInterfacesDom {
  SharedWorkerGlobalScopeImpl.internal_() : super.internal_();
  get runtimeType => SharedWorkerGlobalScope;
  toString() => super.toString();
}
patch class MimeTypeArray {
  factory MimeTypeArray._internalWrap() => new MimeTypeArrayImpl.internal_();

}
class MimeTypeArrayImpl extends MimeTypeArray implements js_library.JSObjectInterfacesDom {
  MimeTypeArrayImpl.internal_() : super.internal_();
  get runtimeType => MimeTypeArray;
  toString() => super.toString();
}
patch class PerformanceRenderTiming {
  factory PerformanceRenderTiming._internalWrap() => new PerformanceRenderTimingImpl.internal_();

}
class PerformanceRenderTimingImpl extends PerformanceRenderTiming implements js_library.JSObjectInterfacesDom {
  PerformanceRenderTimingImpl.internal_() : super.internal_();
  get runtimeType => PerformanceRenderTiming;
  toString() => super.toString();
}
patch class EffectModel {
  factory EffectModel._internalWrap() => new EffectModelImpl.internal_();

}
class EffectModelImpl extends EffectModel implements js_library.JSObjectInterfacesDom {
  EffectModelImpl.internal_() : super.internal_();
  get runtimeType => EffectModel;
  toString() => super.toString();
}
patch class StyleSheet {
  factory StyleSheet._internalWrap() => new StyleSheetImpl.internal_();

}
class StyleSheetImpl extends StyleSheet implements js_library.JSObjectInterfacesDom {
  StyleSheetImpl.internal_() : super.internal_();
  get runtimeType => StyleSheet;
  toString() => super.toString();
}
patch class TableRowElement {
  factory TableRowElement._internalWrap() => new TableRowElementImpl.internal_();

}
class TableRowElementImpl extends TableRowElement implements js_library.JSObjectInterfacesDom {
  TableRowElementImpl.internal_() : super.internal_();
  get runtimeType => TableRowElement;
  toString() => super.toString();
}
patch class Geofencing {
  factory Geofencing._internalWrap() => new GeofencingImpl.internal_();

}
class GeofencingImpl extends Geofencing implements js_library.JSObjectInterfacesDom {
  GeofencingImpl.internal_() : super.internal_();
  get runtimeType => Geofencing;
  toString() => super.toString();
}
patch class NodeList {
  factory NodeList._internalWrap() => new NodeListImpl.internal_();

}
class NodeListImpl extends NodeList implements js_library.JSObjectInterfacesDom {
  NodeListImpl.internal_() : super.internal_();
  get runtimeType => NodeList;
  toString() => super.toString();
}
patch class MidiAccess {
  factory MidiAccess._internalWrap() => new MidiAccessImpl.internal_();

}
class MidiAccessImpl extends MidiAccess implements js_library.JSObjectInterfacesDom {
  MidiAccessImpl.internal_() : super.internal_();
  get runtimeType => MidiAccess;
  toString() => super.toString();
}
patch class CssStyleRule {
  factory CssStyleRule._internalWrap() => new CssStyleRuleImpl.internal_();

}
class CssStyleRuleImpl extends CssStyleRule implements js_library.JSObjectInterfacesDom {
  CssStyleRuleImpl.internal_() : super.internal_();
  get runtimeType => CssStyleRule;
  toString() => super.toString();
}
patch class DomError {
  factory DomError._internalWrap() => new DomErrorImpl.internal_();

}
class DomErrorImpl extends DomError implements js_library.JSObjectInterfacesDom {
  DomErrorImpl.internal_() : super.internal_();
  get runtimeType => DomError;
  toString() => super.toString();
}
patch class BluetoothUuid {
  factory BluetoothUuid._internalWrap() => new BluetoothUuidImpl.internal_();

}
class BluetoothUuidImpl extends BluetoothUuid implements js_library.JSObjectInterfacesDom {
  BluetoothUuidImpl.internal_() : super.internal_();
  get runtimeType => BluetoothUuid;
  toString() => super.toString();
}
patch class HashChangeEvent {
  factory HashChangeEvent._internalWrap() => new HashChangeEventImpl.internal_();

}
class HashChangeEventImpl extends HashChangeEvent implements js_library.JSObjectInterfacesDom {
  HashChangeEventImpl.internal_() : super.internal_();
  get runtimeType => HashChangeEvent;
  toString() => super.toString();
}
patch class InputElement {
  factory InputElement._internalWrap() => new InputElementImpl.internal_();

}
class InputElementImpl extends InputElement implements js_library.JSObjectInterfacesDom {
  InputElementImpl.internal_() : super.internal_();
  get runtimeType => InputElement;
  toString() => super.toString();
}
patch class CDataSection {
  factory CDataSection._internalWrap() => new CDataSectionImpl.internal_();

}
class CDataSectionImpl extends CDataSection implements js_library.JSObjectInterfacesDom {
  CDataSectionImpl.internal_() : super.internal_();
  get runtimeType => CDataSection;
  toString() => super.toString();
}
patch class CssStyleSheet {
  factory CssStyleSheet._internalWrap() => new CssStyleSheetImpl.internal_();

}
class CssStyleSheetImpl extends CssStyleSheet implements js_library.JSObjectInterfacesDom {
  CssStyleSheetImpl.internal_() : super.internal_();
  get runtimeType => CssStyleSheet;
  toString() => super.toString();
}
patch class DomRectReadOnly {
  factory DomRectReadOnly._internalWrap() => new DomRectReadOnlyImpl.internal_();

}
class DomRectReadOnlyImpl extends DomRectReadOnly implements js_library.JSObjectInterfacesDom {
  DomRectReadOnlyImpl.internal_() : super.internal_();
  get runtimeType => DomRectReadOnly;
  toString() => super.toString();
}
patch class SyncEvent {
  factory SyncEvent._internalWrap() => new SyncEventImpl.internal_();

}
class SyncEventImpl extends SyncEvent implements js_library.JSObjectInterfacesDom {
  SyncEventImpl.internal_() : super.internal_();
  get runtimeType => SyncEvent;
  toString() => super.toString();
}
patch class CssSupportsRule {
  factory CssSupportsRule._internalWrap() => new CssSupportsRuleImpl.internal_();

}
class CssSupportsRuleImpl extends CssSupportsRule implements js_library.JSObjectInterfacesDom {
  CssSupportsRuleImpl.internal_() : super.internal_();
  get runtimeType => CssSupportsRule;
  toString() => super.toString();
}
patch class DomParser {
  factory DomParser._internalWrap() => new DomParserImpl.internal_();

}
class DomParserImpl extends DomParser implements js_library.JSObjectInterfacesDom {
  DomParserImpl.internal_() : super.internal_();
  get runtimeType => DomParser;
  toString() => super.toString();
}
patch class LIElement {
  factory LIElement._internalWrap() => new LIElementImpl.internal_();

}
class LIElementImpl extends LIElement implements js_library.JSObjectInterfacesDom {
  LIElementImpl.internal_() : super.internal_();
  get runtimeType => LIElement;
  toString() => super.toString();
}
patch class CrossOriginServiceWorkerClient {
  factory CrossOriginServiceWorkerClient._internalWrap() => new CrossOriginServiceWorkerClientImpl.internal_();

}
class CrossOriginServiceWorkerClientImpl extends CrossOriginServiceWorkerClient implements js_library.JSObjectInterfacesDom {
  CrossOriginServiceWorkerClientImpl.internal_() : super.internal_();
  get runtimeType => CrossOriginServiceWorkerClient;
  toString() => super.toString();
}
patch class ServiceWorkerGlobalScope {
  factory ServiceWorkerGlobalScope._internalWrap() => new ServiceWorkerGlobalScopeImpl.internal_();

}
class ServiceWorkerGlobalScopeImpl extends ServiceWorkerGlobalScope implements js_library.JSObjectInterfacesDom {
  ServiceWorkerGlobalScopeImpl.internal_() : super.internal_();
  get runtimeType => ServiceWorkerGlobalScope;
  toString() => super.toString();
}
patch class InputDevice {
  factory InputDevice._internalWrap() => new InputDeviceImpl.internal_();

}
class InputDeviceImpl extends InputDevice implements js_library.JSObjectInterfacesDom {
  InputDeviceImpl.internal_() : super.internal_();
  get runtimeType => InputDevice;
  toString() => super.toString();
}
patch class MediaSession {
  factory MediaSession._internalWrap() => new MediaSessionImpl.internal_();

}
class MediaSessionImpl extends MediaSession implements js_library.JSObjectInterfacesDom {
  MediaSessionImpl.internal_() : super.internal_();
  get runtimeType => MediaSession;
  toString() => super.toString();
}
patch class PreElement {
  factory PreElement._internalWrap() => new PreElementImpl.internal_();

}
class PreElementImpl extends PreElement implements js_library.JSObjectInterfacesDom {
  PreElementImpl.internal_() : super.internal_();
  get runtimeType => PreElement;
  toString() => super.toString();
}
patch class _NamedNodeMap {
  factory _NamedNodeMap._internalWrap() => new _NamedNodeMapImpl.internal_();

}
class _NamedNodeMapImpl extends _NamedNodeMap implements js_library.JSObjectInterfacesDom {
  _NamedNodeMapImpl.internal_() : super.internal_();
  get runtimeType => _NamedNodeMap;
  toString() => super.toString();
}
patch class StyleElement {
  factory StyleElement._internalWrap() => new StyleElementImpl.internal_();

}
class StyleElementImpl extends StyleElement implements js_library.JSObjectInterfacesDom {
  StyleElementImpl.internal_() : super.internal_();
  get runtimeType => StyleElement;
  toString() => super.toString();
}
patch class TrackEvent {
  factory TrackEvent._internalWrap() => new TrackEventImpl.internal_();

}
class TrackEventImpl extends TrackEvent implements js_library.JSObjectInterfacesDom {
  TrackEventImpl.internal_() : super.internal_();
  get runtimeType => TrackEvent;
  toString() => super.toString();
}
patch class Performance {
  factory Performance._internalWrap() => new PerformanceImpl.internal_();

}
class PerformanceImpl extends Performance implements js_library.JSObjectInterfacesDom {
  PerformanceImpl.internal_() : super.internal_();
  get runtimeType => Performance;
  toString() => super.toString();
}
patch class CssKeyframeRule {
  factory CssKeyframeRule._internalWrap() => new CssKeyframeRuleImpl.internal_();

}
class CssKeyframeRuleImpl extends CssKeyframeRule implements js_library.JSObjectInterfacesDom {
  CssKeyframeRuleImpl.internal_() : super.internal_();
  get runtimeType => CssKeyframeRule;
  toString() => super.toString();
}
patch class MidiInputMap {
  factory MidiInputMap._internalWrap() => new MidiInputMapImpl.internal_();

}
class MidiInputMapImpl extends MidiInputMap implements js_library.JSObjectInterfacesDom {
  MidiInputMapImpl.internal_() : super.internal_();
  get runtimeType => MidiInputMap;
  toString() => super.toString();
}
patch class XmlDocument {
  factory XmlDocument._internalWrap() => new XmlDocumentImpl.internal_();

}
class XmlDocumentImpl extends XmlDocument implements js_library.JSObjectInterfacesDom {
  XmlDocumentImpl.internal_() : super.internal_();
  get runtimeType => XmlDocument;
  toString() => super.toString();
}
patch class VREyeParameters {
  factory VREyeParameters._internalWrap() => new VREyeParametersImpl.internal_();

}
class VREyeParametersImpl extends VREyeParameters implements js_library.JSObjectInterfacesDom {
  VREyeParametersImpl.internal_() : super.internal_();
  get runtimeType => VREyeParameters;
  toString() => super.toString();
}
patch class Credential {
  factory Credential._internalWrap() => new CredentialImpl.internal_();

}
class CredentialImpl extends Credential implements js_library.JSObjectInterfacesDom {
  CredentialImpl.internal_() : super.internal_();
  get runtimeType => Credential;
  toString() => super.toString();
}
patch class DomException {
  factory DomException._internalWrap() => new DomExceptionImpl.internal_();

}
class DomExceptionImpl extends DomException implements js_library.JSObjectInterfacesDom {
  DomExceptionImpl.internal_() : super.internal_();
  get runtimeType => DomException;
  toString() => super.toString();
}
patch class LegendElement {
  factory LegendElement._internalWrap() => new LegendElementImpl.internal_();

}
class LegendElementImpl extends LegendElement implements js_library.JSObjectInterfacesDom {
  LegendElementImpl.internal_() : super.internal_();
  get runtimeType => LegendElement;
  toString() => super.toString();
}
patch class HttpRequestEventTarget {
  factory HttpRequestEventTarget._internalWrap() => new HttpRequestEventTargetImpl.internal_();

}
class HttpRequestEventTargetImpl extends HttpRequestEventTarget implements js_library.JSObjectInterfacesDom {
  HttpRequestEventTargetImpl.internal_() : super.internal_();
  get runtimeType => HttpRequestEventTarget;
  toString() => super.toString();
}
patch class UnknownElement {
  factory UnknownElement._internalWrap() => new UnknownElementImpl.internal_();

}
class UnknownElementImpl extends UnknownElement implements js_library.JSObjectInterfacesDom {
  UnknownElementImpl.internal_() : super.internal_();
  get runtimeType => UnknownElement;
  toString() => super.toString();
}
patch class _RadioNodeList {
  factory _RadioNodeList._internalWrap() => new _RadioNodeListImpl.internal_();

}
class _RadioNodeListImpl extends _RadioNodeList implements js_library.JSObjectInterfacesDom {
  _RadioNodeListImpl.internal_() : super.internal_();
  get runtimeType => _RadioNodeList;
  toString() => super.toString();
}
patch class NavigatorUserMediaError {
  factory NavigatorUserMediaError._internalWrap() => new NavigatorUserMediaErrorImpl.internal_();

}
class NavigatorUserMediaErrorImpl extends NavigatorUserMediaError implements js_library.JSObjectInterfacesDom {
  NavigatorUserMediaErrorImpl.internal_() : super.internal_();
  get runtimeType => NavigatorUserMediaError;
  toString() => super.toString();
}
patch class ImageBitmap {
  factory ImageBitmap._internalWrap() => new ImageBitmapImpl.internal_();

}
class ImageBitmapImpl extends ImageBitmap implements js_library.JSObjectInterfacesDom {
  ImageBitmapImpl.internal_() : super.internal_();
  get runtimeType => ImageBitmap;
  toString() => super.toString();
}
patch class AudioTrack {
  factory AudioTrack._internalWrap() => new AudioTrackImpl.internal_();

}
class AudioTrackImpl extends AudioTrack implements js_library.JSObjectInterfacesDom {
  AudioTrackImpl.internal_() : super.internal_();
  get runtimeType => AudioTrack;
  toString() => super.toString();
}
patch class ReadableByteStream {
  factory ReadableByteStream._internalWrap() => new ReadableByteStreamImpl.internal_();

}
class ReadableByteStreamImpl extends ReadableByteStream implements js_library.JSObjectInterfacesDom {
  ReadableByteStreamImpl.internal_() : super.internal_();
  get runtimeType => ReadableByteStream;
  toString() => super.toString();
}
patch class _HTMLFrameElement {
  factory _HTMLFrameElement._internalWrap() => new _HTMLFrameElementImpl.internal_();

}
class _HTMLFrameElementImpl extends _HTMLFrameElement implements js_library.JSObjectInterfacesDom {
  _HTMLFrameElementImpl.internal_() : super.internal_();
  get runtimeType => _HTMLFrameElement;
  toString() => super.toString();
}
patch class Body {
  factory Body._internalWrap() => new BodyImpl.internal_();

}
class BodyImpl extends Body implements js_library.JSObjectInterfacesDom {
  BodyImpl.internal_() : super.internal_();
  get runtimeType => Body;
  toString() => super.toString();
}
patch class MediaKeySystemAccess {
  factory MediaKeySystemAccess._internalWrap() => new MediaKeySystemAccessImpl.internal_();

}
class MediaKeySystemAccessImpl extends MediaKeySystemAccess implements js_library.JSObjectInterfacesDom {
  MediaKeySystemAccessImpl.internal_() : super.internal_();
  get runtimeType => MediaKeySystemAccess;
  toString() => super.toString();
}
patch class BluetoothGattService {
  factory BluetoothGattService._internalWrap() => new BluetoothGattServiceImpl.internal_();

}
class BluetoothGattServiceImpl extends BluetoothGattService implements js_library.JSObjectInterfacesDom {
  BluetoothGattServiceImpl.internal_() : super.internal_();
  get runtimeType => BluetoothGattService;
  toString() => super.toString();
}
patch class _Attr {
  factory _Attr._internalWrap() => new _AttrImpl.internal_();

}
class _AttrImpl extends _Attr implements js_library.JSObjectInterfacesDom {
  _AttrImpl.internal_() : super.internal_();
  get runtimeType => _Attr;
  toString() => super.toString();
}
patch class CanvasRenderingContext2D {
  factory CanvasRenderingContext2D._internalWrap() => new CanvasRenderingContext2DImpl.internal_();

}
class CanvasRenderingContext2DImpl extends CanvasRenderingContext2D implements js_library.JSObjectInterfacesDom {
  CanvasRenderingContext2DImpl.internal_() : super.internal_();
  get runtimeType => CanvasRenderingContext2D;
  toString() => super.toString();
}
patch class OListElement {
  factory OListElement._internalWrap() => new OListElementImpl.internal_();

}
class OListElementImpl extends OListElement implements js_library.JSObjectInterfacesDom {
  OListElementImpl.internal_() : super.internal_();
  get runtimeType => OListElement;
  toString() => super.toString();
}
patch class ApplicationCache {
  factory ApplicationCache._internalWrap() => new ApplicationCacheImpl.internal_();

}
class ApplicationCacheImpl extends ApplicationCache implements js_library.JSObjectInterfacesDom {
  ApplicationCacheImpl.internal_() : super.internal_();
  get runtimeType => ApplicationCache;
  toString() => super.toString();
}
patch class Clients {
  factory Clients._internalWrap() => new ClientsImpl.internal_();

}
class ClientsImpl extends Clients implements js_library.JSObjectInterfacesDom {
  ClientsImpl.internal_() : super.internal_();
  get runtimeType => Clients;
  toString() => super.toString();
}
patch class RtcPeerConnection {
  factory RtcPeerConnection._internalWrap() => new RtcPeerConnectionImpl.internal_();

}
class RtcPeerConnectionImpl extends RtcPeerConnection implements js_library.JSObjectInterfacesDom {
  RtcPeerConnectionImpl.internal_() : super.internal_();
  get runtimeType => RtcPeerConnection;
  toString() => super.toString();
}
patch class VideoElement {
  factory VideoElement._internalWrap() => new VideoElementImpl.internal_();

}
class VideoElementImpl extends VideoElement implements js_library.JSObjectInterfacesDom {
  VideoElementImpl.internal_() : super.internal_();
  get runtimeType => VideoElement;
  toString() => super.toString();
}
patch class OutputElement {
  factory OutputElement._internalWrap() => new OutputElementImpl.internal_();

}
class OutputElementImpl extends OutputElement implements js_library.JSObjectInterfacesDom {
  OutputElementImpl.internal_() : super.internal_();
  get runtimeType => OutputElement;
  toString() => super.toString();
}
patch class Coordinates {
  factory Coordinates._internalWrap() => new CoordinatesImpl.internal_();

}
class CoordinatesImpl extends Coordinates implements js_library.JSObjectInterfacesDom {
  CoordinatesImpl.internal_() : super.internal_();
  get runtimeType => Coordinates;
  toString() => super.toString();
}
patch class NetworkInformation {
  factory NetworkInformation._internalWrap() => new NetworkInformationImpl.internal_();

}
class NetworkInformationImpl extends NetworkInformation implements js_library.JSObjectInterfacesDom {
  NetworkInformationImpl.internal_() : super.internal_();
  get runtimeType => NetworkInformation;
  toString() => super.toString();
}
patch class FocusEvent {
  factory FocusEvent._internalWrap() => new FocusEventImpl.internal_();

}
class FocusEventImpl extends FocusEvent implements js_library.JSObjectInterfacesDom {
  FocusEventImpl.internal_() : super.internal_();
  get runtimeType => FocusEvent;
  toString() => super.toString();
}
patch class SpeechGrammarList {
  factory SpeechGrammarList._internalWrap() => new SpeechGrammarListImpl.internal_();

}
class SpeechGrammarListImpl extends SpeechGrammarList implements js_library.JSObjectInterfacesDom {
  SpeechGrammarListImpl.internal_() : super.internal_();
  get runtimeType => SpeechGrammarList;
  toString() => super.toString();
}
patch class Range {
  factory Range._internalWrap() => new RangeImpl.internal_();

}
class RangeImpl extends Range implements js_library.JSObjectInterfacesDom {
  RangeImpl.internal_() : super.internal_();
  get runtimeType => Range;
  toString() => super.toString();
}
patch class SpeechGrammar {
  factory SpeechGrammar._internalWrap() => new SpeechGrammarImpl.internal_();

}
class SpeechGrammarImpl extends SpeechGrammar implements js_library.JSObjectInterfacesDom {
  SpeechGrammarImpl.internal_() : super.internal_();
  get runtimeType => SpeechGrammar;
  toString() => super.toString();
}
patch class WorkerGlobalScope {
  factory WorkerGlobalScope._internalWrap() => new WorkerGlobalScopeImpl.internal_();

}
class WorkerGlobalScopeImpl extends WorkerGlobalScope implements js_library.JSObjectInterfacesDom {
  WorkerGlobalScopeImpl.internal_() : super.internal_();
  get runtimeType => WorkerGlobalScope;
  toString() => super.toString();
}
patch class ScreenOrientation {
  factory ScreenOrientation._internalWrap() => new ScreenOrientationImpl.internal_();

}
class ScreenOrientationImpl extends ScreenOrientation implements js_library.JSObjectInterfacesDom {
  ScreenOrientationImpl.internal_() : super.internal_();
  get runtimeType => ScreenOrientation;
  toString() => super.toString();
}
patch class NonElementParentNode {
  factory NonElementParentNode._internalWrap() => new NonElementParentNodeImpl.internal_();

}
class NonElementParentNodeImpl extends NonElementParentNode implements js_library.JSObjectInterfacesDom {
  NonElementParentNodeImpl.internal_() : super.internal_();
  get runtimeType => NonElementParentNode;
  toString() => super.toString();
}
patch class TitleElement {
  factory TitleElement._internalWrap() => new TitleElementImpl.internal_();

}
class TitleElementImpl extends TitleElement implements js_library.JSObjectInterfacesDom {
  TitleElementImpl.internal_() : super.internal_();
  get runtimeType => TitleElement;
  toString() => super.toString();
}
patch class MidiConnectionEvent {
  factory MidiConnectionEvent._internalWrap() => new MidiConnectionEventImpl.internal_();

}
class MidiConnectionEventImpl extends MidiConnectionEvent implements js_library.JSObjectInterfacesDom {
  MidiConnectionEventImpl.internal_() : super.internal_();
  get runtimeType => MidiConnectionEvent;
  toString() => super.toString();
}
patch class NotificationEvent {
  factory NotificationEvent._internalWrap() => new NotificationEventImpl.internal_();

}
class NotificationEventImpl extends NotificationEvent implements js_library.JSObjectInterfacesDom {
  NotificationEventImpl.internal_() : super.internal_();
  get runtimeType => NotificationEvent;
  toString() => super.toString();
}
patch class BeforeInstallPromptEvent {
  factory BeforeInstallPromptEvent._internalWrap() => new BeforeInstallPromptEventImpl.internal_();

}
class BeforeInstallPromptEventImpl extends BeforeInstallPromptEvent implements js_library.JSObjectInterfacesDom {
  BeforeInstallPromptEventImpl.internal_() : super.internal_();
  get runtimeType => BeforeInstallPromptEvent;
  toString() => super.toString();
}
patch class _CanvasPathMethods {
  factory _CanvasPathMethods._internalWrap() => new _CanvasPathMethodsImpl.internal_();

}
class _CanvasPathMethodsImpl extends _CanvasPathMethods implements js_library.JSObjectInterfacesDom {
  _CanvasPathMethodsImpl.internal_() : super.internal_();
  get runtimeType => _CanvasPathMethods;
  toString() => super.toString();
}
patch class UrlUtils {
  factory UrlUtils._internalWrap() => new UrlUtilsImpl.internal_();

}
class UrlUtilsImpl extends UrlUtils implements js_library.JSObjectInterfacesDom {
  UrlUtilsImpl.internal_() : super.internal_();
  get runtimeType => UrlUtils;
  toString() => super.toString();
}
patch class SelectElement {
  factory SelectElement._internalWrap() => new SelectElementImpl.internal_();

}
class SelectElementImpl extends SelectElement implements js_library.JSObjectInterfacesDom {
  SelectElementImpl.internal_() : super.internal_();
  get runtimeType => SelectElement;
  toString() => super.toString();
}
patch class Bluetooth {
  factory Bluetooth._internalWrap() => new BluetoothImpl.internal_();

}
class BluetoothImpl extends Bluetooth implements js_library.JSObjectInterfacesDom {
  BluetoothImpl.internal_() : super.internal_();
  get runtimeType => Bluetooth;
  toString() => super.toString();
}
patch class BluetoothDevice {
  factory BluetoothDevice._internalWrap() => new BluetoothDeviceImpl.internal_();

}
class BluetoothDeviceImpl extends BluetoothDevice implements js_library.JSObjectInterfacesDom {
  BluetoothDeviceImpl.internal_() : super.internal_();
  get runtimeType => BluetoothDevice;
  toString() => super.toString();
}
patch class ConsoleBase {
  factory ConsoleBase._internalWrap() => new ConsoleBaseImpl.internal_();

}
class ConsoleBaseImpl extends ConsoleBase implements js_library.JSObjectInterfacesDom {
  ConsoleBaseImpl.internal_() : super.internal_();
  get runtimeType => ConsoleBase;
  toString() => super.toString();
}
patch class AudioElement {
  factory AudioElement._internalWrap() => new AudioElementImpl.internal_();

}
class AudioElementImpl extends AudioElement implements js_library.JSObjectInterfacesDom {
  AudioElementImpl.internal_() : super.internal_();
  get runtimeType => AudioElement;
  toString() => super.toString();
}
patch class PushMessageData {
  factory PushMessageData._internalWrap() => new PushMessageDataImpl.internal_();

}
class PushMessageDataImpl extends PushMessageData implements js_library.JSObjectInterfacesDom {
  PushMessageDataImpl.internal_() : super.internal_();
  get runtimeType => PushMessageData;
  toString() => super.toString();
}
patch class SpeechRecognitionEvent {
  factory SpeechRecognitionEvent._internalWrap() => new SpeechRecognitionEventImpl.internal_();

}
class SpeechRecognitionEventImpl extends SpeechRecognitionEvent implements js_library.JSObjectInterfacesDom {
  SpeechRecognitionEventImpl.internal_() : super.internal_();
  get runtimeType => SpeechRecognitionEvent;
  toString() => super.toString();
}
patch class WebSocket {
  factory WebSocket._internalWrap() => new WebSocketImpl.internal_();

}
class WebSocketImpl extends WebSocket implements js_library.JSObjectInterfacesDom {
  WebSocketImpl.internal_() : super.internal_();
  get runtimeType => WebSocket;
  toString() => super.toString();
}
patch class _XMLHttpRequestProgressEvent {
  factory _XMLHttpRequestProgressEvent._internalWrap() => new _XMLHttpRequestProgressEventImpl.internal_();

}
class _XMLHttpRequestProgressEventImpl extends _XMLHttpRequestProgressEvent implements js_library.JSObjectInterfacesDom {
  _XMLHttpRequestProgressEventImpl.internal_() : super.internal_();
  get runtimeType => _XMLHttpRequestProgressEvent;
  toString() => super.toString();
}
patch class Location {
  factory Location._internalWrap() => new LocationImpl.internal_();

}
class LocationImpl extends Location implements js_library.JSObjectInterfacesDom {
  LocationImpl.internal_() : super.internal_();
  get runtimeType => Location;
  toString() => super.toString();
}
patch class PerformanceEntry {
  factory PerformanceEntry._internalWrap() => new PerformanceEntryImpl.internal_();

}
class PerformanceEntryImpl extends PerformanceEntry implements js_library.JSObjectInterfacesDom {
  PerformanceEntryImpl.internal_() : super.internal_();
  get runtimeType => PerformanceEntry;
  toString() => super.toString();
}
patch class Client {
  factory Client._internalWrap() => new ClientImpl.internal_();

}
class ClientImpl extends Client implements js_library.JSObjectInterfacesDom {
  ClientImpl.internal_() : super.internal_();
  get runtimeType => Client;
  toString() => super.toString();
}
patch class _Cache {
  factory _Cache._internalWrap() => new _CacheImpl.internal_();

}
class _CacheImpl extends _Cache implements js_library.JSObjectInterfacesDom {
  _CacheImpl.internal_() : super.internal_();
  get runtimeType => _Cache;
  toString() => super.toString();
}
patch class MimeType {
  factory MimeType._internalWrap() => new MimeTypeImpl.internal_();

}
class MimeTypeImpl extends MimeType implements js_library.JSObjectInterfacesDom {
  MimeTypeImpl.internal_() : super.internal_();
  get runtimeType => MimeType;
  toString() => super.toString();
}
patch class MidiOutputMap {
  factory MidiOutputMap._internalWrap() => new MidiOutputMapImpl.internal_();

}
class MidiOutputMapImpl extends MidiOutputMap implements js_library.JSObjectInterfacesDom {
  MidiOutputMapImpl.internal_() : super.internal_();
  get runtimeType => MidiOutputMap;
  toString() => super.toString();
}
patch class PointerEvent {
  factory PointerEvent._internalWrap() => new PointerEventImpl.internal_();

}
class PointerEventImpl extends PointerEvent implements js_library.JSObjectInterfacesDom {
  PointerEventImpl.internal_() : super.internal_();
  get runtimeType => PointerEvent;
  toString() => super.toString();
}
patch class ChildNode {
  factory ChildNode._internalWrap() => new ChildNodeImpl.internal_();

}
class ChildNodeImpl extends ChildNode implements js_library.JSObjectInterfacesDom {
  ChildNodeImpl.internal_() : super.internal_();
  get runtimeType => ChildNode;
  toString() => super.toString();
}
patch class Geolocation {
  factory Geolocation._internalWrap() => new GeolocationImpl.internal_();

}
class GeolocationImpl extends Geolocation implements js_library.JSObjectInterfacesDom {
  GeolocationImpl.internal_() : super.internal_();
  get runtimeType => Geolocation;
  toString() => super.toString();
}
patch class _CssRuleList {
  factory _CssRuleList._internalWrap() => new _CssRuleListImpl.internal_();

}
class _CssRuleListImpl extends _CssRuleList implements js_library.JSObjectInterfacesDom {
  _CssRuleListImpl.internal_() : super.internal_();
  get runtimeType => _CssRuleList;
  toString() => super.toString();
}
patch class MediaKeyEvent {
  factory MediaKeyEvent._internalWrap() => new MediaKeyEventImpl.internal_();

}
class MediaKeyEventImpl extends MediaKeyEvent implements js_library.JSObjectInterfacesDom {
  MediaKeyEventImpl.internal_() : super.internal_();
  get runtimeType => MediaKeyEvent;
  toString() => super.toString();
}
patch class CompositorWorker {
  factory CompositorWorker._internalWrap() => new CompositorWorkerImpl.internal_();

}
class CompositorWorkerImpl extends CompositorWorker implements js_library.JSObjectInterfacesDom {
  CompositorWorkerImpl.internal_() : super.internal_();
  get runtimeType => CompositorWorker;
  toString() => super.toString();
}
patch class ProgressElement {
  factory ProgressElement._internalWrap() => new ProgressElementImpl.internal_();

}
class ProgressElementImpl extends ProgressElement implements js_library.JSObjectInterfacesDom {
  ProgressElementImpl.internal_() : super.internal_();
  get runtimeType => ProgressElement;
  toString() => super.toString();
}
patch class SharedArrayBuffer {
  factory SharedArrayBuffer._internalWrap() => new SharedArrayBufferImpl.internal_();

}
class SharedArrayBufferImpl extends SharedArrayBuffer implements js_library.JSObjectInterfacesDom {
  SharedArrayBufferImpl.internal_() : super.internal_();
  get runtimeType => SharedArrayBuffer;
  toString() => super.toString();
}
patch class CrossOriginConnectEvent {
  factory CrossOriginConnectEvent._internalWrap() => new CrossOriginConnectEventImpl.internal_();

}
class CrossOriginConnectEventImpl extends CrossOriginConnectEvent implements js_library.JSObjectInterfacesDom {
  CrossOriginConnectEventImpl.internal_() : super.internal_();
  get runtimeType => CrossOriginConnectEvent;
  toString() => super.toString();
}
patch class BeforeUnloadEvent {
  factory BeforeUnloadEvent._internalWrap() => new BeforeUnloadEventImpl.internal_();

}
class BeforeUnloadEventImpl extends BeforeUnloadEvent implements js_library.JSObjectInterfacesDom {
  BeforeUnloadEventImpl.internal_() : super.internal_();
  get runtimeType => BeforeUnloadEvent;
  toString() => super.toString();
}
patch class DataTransferItem {
  factory DataTransferItem._internalWrap() => new DataTransferItemImpl.internal_();

}
class DataTransferItemImpl extends DataTransferItem implements js_library.JSObjectInterfacesDom {
  DataTransferItemImpl.internal_() : super.internal_();
  get runtimeType => DataTransferItem;
  toString() => super.toString();
}
patch class _HTMLAllCollection {
  factory _HTMLAllCollection._internalWrap() => new _HTMLAllCollectionImpl.internal_();

}
class _HTMLAllCollectionImpl extends _HTMLAllCollection implements js_library.JSObjectInterfacesDom {
  _HTMLAllCollectionImpl.internal_() : super.internal_();
  get runtimeType => _HTMLAllCollection;
  toString() => super.toString();
}
patch class ServicePortCollection {
  factory ServicePortCollection._internalWrap() => new ServicePortCollectionImpl.internal_();

}
class ServicePortCollectionImpl extends ServicePortCollection implements js_library.JSObjectInterfacesDom {
  ServicePortCollectionImpl.internal_() : super.internal_();
  get runtimeType => ServicePortCollection;
  toString() => super.toString();
}
patch class KeygenElement {
  factory KeygenElement._internalWrap() => new KeygenElementImpl.internal_();

}
class KeygenElementImpl extends KeygenElement implements js_library.JSObjectInterfacesDom {
  KeygenElementImpl.internal_() : super.internal_();
  get runtimeType => KeygenElement;
  toString() => super.toString();
}
patch class CryptoKey {
  factory CryptoKey._internalWrap() => new CryptoKeyImpl.internal_();

}
class CryptoKeyImpl extends CryptoKey implements js_library.JSObjectInterfacesDom {
  CryptoKeyImpl.internal_() : super.internal_();
  get runtimeType => CryptoKey;
  toString() => super.toString();
}
patch class CssKeyframesRule {
  factory CssKeyframesRule._internalWrap() => new CssKeyframesRuleImpl.internal_();

}
class CssKeyframesRuleImpl extends CssKeyframesRule implements js_library.JSObjectInterfacesDom {
  CssKeyframesRuleImpl.internal_() : super.internal_();
  get runtimeType => CssKeyframesRule;
  toString() => super.toString();
}
patch class _HTMLMarqueeElement {
  factory _HTMLMarqueeElement._internalWrap() => new _HTMLMarqueeElementImpl.internal_();

}
class _HTMLMarqueeElementImpl extends _HTMLMarqueeElement implements js_library.JSObjectInterfacesDom {
  _HTMLMarqueeElementImpl.internal_() : super.internal_();
  get runtimeType => _HTMLMarqueeElement;
  toString() => super.toString();
}
patch class TextEvent {
  factory TextEvent._internalWrap() => new TextEventImpl.internal_();

}
class TextEventImpl extends TextEvent implements js_library.JSObjectInterfacesDom {
  TextEventImpl.internal_() : super.internal_();
  get runtimeType => TextEvent;
  toString() => super.toString();
}
patch class _EntrySync {
  factory _EntrySync._internalWrap() => new _EntrySyncImpl.internal_();

}
class _EntrySyncImpl extends _EntrySync implements js_library.JSObjectInterfacesDom {
  _EntrySyncImpl.internal_() : super.internal_();
  get runtimeType => _EntrySync;
  toString() => super.toString();
}
patch class GeofencingEvent {
  factory GeofencingEvent._internalWrap() => new GeofencingEventImpl.internal_();

}
class GeofencingEventImpl extends GeofencingEvent implements js_library.JSObjectInterfacesDom {
  GeofencingEventImpl.internal_() : super.internal_();
  get runtimeType => GeofencingEvent;
  toString() => super.toString();
}
patch class MediaKeys {
  factory MediaKeys._internalWrap() => new MediaKeysImpl.internal_();

}
class MediaKeysImpl extends MediaKeys implements js_library.JSObjectInterfacesDom {
  MediaKeysImpl.internal_() : super.internal_();
  get runtimeType => MediaKeys;
  toString() => super.toString();
}
patch class DomPointReadOnly {
  factory DomPointReadOnly._internalWrap() => new DomPointReadOnlyImpl.internal_();

}
class DomPointReadOnlyImpl extends DomPointReadOnly implements js_library.JSObjectInterfacesDom {
  DomPointReadOnlyImpl.internal_() : super.internal_();
  get runtimeType => DomPointReadOnly;
  toString() => super.toString();
}
patch class WindowBase64 {
  factory WindowBase64._internalWrap() => new WindowBase64Impl.internal_();

}
class WindowBase64Impl extends WindowBase64 implements js_library.JSObjectInterfacesDom {
  WindowBase64Impl.internal_() : super.internal_();
  get runtimeType => WindowBase64;
  toString() => super.toString();
}
patch class SpeechRecognitionError {
  factory SpeechRecognitionError._internalWrap() => new SpeechRecognitionErrorImpl.internal_();

}
class SpeechRecognitionErrorImpl extends SpeechRecognitionError implements js_library.JSObjectInterfacesDom {
  SpeechRecognitionErrorImpl.internal_() : super.internal_();
  get runtimeType => SpeechRecognitionError;
  toString() => super.toString();
}
patch class MidiOutput {
  factory MidiOutput._internalWrap() => new MidiOutputImpl.internal_();

}
class MidiOutputImpl extends MidiOutput implements js_library.JSObjectInterfacesDom {
  MidiOutputImpl.internal_() : super.internal_();
  get runtimeType => MidiOutput;
  toString() => super.toString();
}
patch class EventSource {
  factory EventSource._internalWrap() => new EventSourceImpl.internal_();

}
class EventSourceImpl extends EventSource implements js_library.JSObjectInterfacesDom {
  EventSourceImpl.internal_() : super.internal_();
  get runtimeType => EventSource;
  toString() => super.toString();
}
patch class DeviceOrientationEvent {
  factory DeviceOrientationEvent._internalWrap() => new DeviceOrientationEventImpl.internal_();

}
class DeviceOrientationEventImpl extends DeviceOrientationEvent implements js_library.JSObjectInterfacesDom {
  DeviceOrientationEventImpl.internal_() : super.internal_();
  get runtimeType => DeviceOrientationEvent;
  toString() => super.toString();
}
patch class DirectoryEntry {
  factory DirectoryEntry._internalWrap() => new DirectoryEntryImpl.internal_();

}
class DirectoryEntryImpl extends DirectoryEntry implements js_library.JSObjectInterfacesDom {
  DirectoryEntryImpl.internal_() : super.internal_();
  get runtimeType => DirectoryEntry;
  toString() => super.toString();
}
patch class ShadowElement {
  factory ShadowElement._internalWrap() => new ShadowElementImpl.internal_();

}
class ShadowElementImpl extends ShadowElement implements js_library.JSObjectInterfacesDom {
  ShadowElementImpl.internal_() : super.internal_();
  get runtimeType => ShadowElement;
  toString() => super.toString();
}
patch class AppBannerPromptResult {
  factory AppBannerPromptResult._internalWrap() => new AppBannerPromptResultImpl.internal_();

}
class AppBannerPromptResultImpl extends AppBannerPromptResult implements js_library.JSObjectInterfacesDom {
  AppBannerPromptResultImpl.internal_() : super.internal_();
  get runtimeType => AppBannerPromptResult;
  toString() => super.toString();
}
patch class Blob {
  factory Blob._internalWrap() => new BlobImpl.internal_();

}
class BlobImpl extends Blob implements js_library.JSObjectInterfacesDom {
  BlobImpl.internal_() : super.internal_();
  get runtimeType => Blob;
  toString() => super.toString();
}
patch class VttCue {
  factory VttCue._internalWrap() => new VttCueImpl.internal_();

}
class VttCueImpl extends VttCue implements js_library.JSObjectInterfacesDom {
  VttCueImpl.internal_() : super.internal_();
  get runtimeType => VttCue;
  toString() => super.toString();
}
patch class PopStateEvent {
  factory PopStateEvent._internalWrap() => new PopStateEventImpl.internal_();

}
class PopStateEventImpl extends PopStateEvent implements js_library.JSObjectInterfacesDom {
  PopStateEventImpl.internal_() : super.internal_();
  get runtimeType => PopStateEvent;
  toString() => super.toString();
}
patch class PushSubscription {
  factory PushSubscription._internalWrap() => new PushSubscriptionImpl.internal_();

}
class PushSubscriptionImpl extends PushSubscription implements js_library.JSObjectInterfacesDom {
  PushSubscriptionImpl.internal_() : super.internal_();
  get runtimeType => PushSubscription;
  toString() => super.toString();
}
patch class UrlUtilsReadOnly {
  factory UrlUtilsReadOnly._internalWrap() => new UrlUtilsReadOnlyImpl.internal_();

}
class UrlUtilsReadOnlyImpl extends UrlUtilsReadOnly implements js_library.JSObjectInterfacesDom {
  UrlUtilsReadOnlyImpl.internal_() : super.internal_();
  get runtimeType => UrlUtilsReadOnly;
  toString() => super.toString();
}
patch class MediaError {
  factory MediaError._internalWrap() => new MediaErrorImpl.internal_();

}
class MediaErrorImpl extends MediaError implements js_library.JSObjectInterfacesDom {
  MediaErrorImpl.internal_() : super.internal_();
  get runtimeType => MediaError;
  toString() => super.toString();
}
patch class SourceBufferList {
  factory SourceBufferList._internalWrap() => new SourceBufferListImpl.internal_();

}
class SourceBufferListImpl extends SourceBufferList implements js_library.JSObjectInterfacesDom {
  SourceBufferListImpl.internal_() : super.internal_();
  get runtimeType => SourceBufferList;
  toString() => super.toString();
}
patch class AnimationEffectReadOnly {
  factory AnimationEffectReadOnly._internalWrap() => new AnimationEffectReadOnlyImpl.internal_();

}
class AnimationEffectReadOnlyImpl extends AnimationEffectReadOnly implements js_library.JSObjectInterfacesDom {
  AnimationEffectReadOnlyImpl.internal_() : super.internal_();
  get runtimeType => AnimationEffectReadOnly;
  toString() => super.toString();
}
patch class PerformanceResourceTiming {
  factory PerformanceResourceTiming._internalWrap() => new PerformanceResourceTimingImpl.internal_();

}
class PerformanceResourceTimingImpl extends PerformanceResourceTiming implements js_library.JSObjectInterfacesDom {
  PerformanceResourceTimingImpl.internal_() : super.internal_();
  get runtimeType => PerformanceResourceTiming;
  toString() => super.toString();
}
patch class GeofencingRegion {
  factory GeofencingRegion._internalWrap() => new GeofencingRegionImpl.internal_();

}
class GeofencingRegionImpl extends GeofencingRegion implements js_library.JSObjectInterfacesDom {
  GeofencingRegionImpl.internal_() : super.internal_();
  get runtimeType => GeofencingRegion;
  toString() => super.toString();
}
patch class CharacterData {
  factory CharacterData._internalWrap() => new CharacterDataImpl.internal_();

}
class CharacterDataImpl extends CharacterData implements js_library.JSObjectInterfacesDom {
  CharacterDataImpl.internal_() : super.internal_();
  get runtimeType => CharacterData;
  toString() => super.toString();
}
patch class Css {
  factory Css._internalWrap() => new CssImpl.internal_();

}
class CssImpl extends Css implements js_library.JSObjectInterfacesDom {
  CssImpl.internal_() : super.internal_();
  get runtimeType => Css;
  toString() => super.toString();
}
patch class MidiInput {
  factory MidiInput._internalWrap() => new MidiInputImpl.internal_();

}
class MidiInputImpl extends MidiInput implements js_library.JSObjectInterfacesDom {
  MidiInputImpl.internal_() : super.internal_();
  get runtimeType => MidiInput;
  toString() => super.toString();
}
patch class ServicePortConnectEvent {
  factory ServicePortConnectEvent._internalWrap() => new ServicePortConnectEventImpl.internal_();

}
class ServicePortConnectEventImpl extends ServicePortConnectEvent implements js_library.JSObjectInterfacesDom {
  ServicePortConnectEventImpl.internal_() : super.internal_();
  get runtimeType => ServicePortConnectEvent;
  toString() => super.toString();
}
patch class ExtendableEvent {
  factory ExtendableEvent._internalWrap() => new ExtendableEventImpl.internal_();

}
class ExtendableEventImpl extends ExtendableEvent implements js_library.JSObjectInterfacesDom {
  ExtendableEventImpl.internal_() : super.internal_();
  get runtimeType => ExtendableEvent;
  toString() => super.toString();
}
patch class MediaStreamEvent {
  factory MediaStreamEvent._internalWrap() => new MediaStreamEventImpl.internal_();

}
class MediaStreamEventImpl extends MediaStreamEvent implements js_library.JSObjectInterfacesDom {
  MediaStreamEventImpl.internal_() : super.internal_();
  get runtimeType => MediaStreamEvent;
  toString() => super.toString();
}
patch class XPathNSResolver {
  factory XPathNSResolver._internalWrap() => new XPathNSResolverImpl.internal_();

}
class XPathNSResolverImpl extends XPathNSResolver implements js_library.JSObjectInterfacesDom {
  XPathNSResolverImpl.internal_() : super.internal_();
  get runtimeType => XPathNSResolver;
  toString() => super.toString();
}
patch class _FileWriterSync {
  factory _FileWriterSync._internalWrap() => new _FileWriterSyncImpl.internal_();

}
class _FileWriterSyncImpl extends _FileWriterSync implements js_library.JSObjectInterfacesDom {
  _FileWriterSyncImpl.internal_() : super.internal_();
  get runtimeType => _FileWriterSync;
  toString() => super.toString();
}

"""],"dart:indexed_db": ["dart:indexed_db", "dart:indexed_db_js_interop_patch.dart", """import 'dart:js' as js_library;

/**
 * Placeholder object for cases where we need to determine exactly how many
 * args were passed to a function.
 */
const _UNDEFINED_JS_CONST = const Object();

patch class IdbFactory {
  factory IdbFactory._internalWrap() => new IdbFactoryImpl.internal_();

}
class IdbFactoryImpl extends IdbFactory implements js_library.JSObjectInterfacesDom {
  IdbFactoryImpl.internal_() : super.internal_();
  get runtimeType => IdbFactory;
  toString() => super.toString();
}
patch class Cursor {
  factory Cursor._internalWrap() => new CursorImpl.internal_();

}
class CursorImpl extends Cursor implements js_library.JSObjectInterfacesDom {
  CursorImpl.internal_() : super.internal_();
  get runtimeType => Cursor;
  toString() => super.toString();
}
patch class Transaction {
  factory Transaction._internalWrap() => new TransactionImpl.internal_();

}
class TransactionImpl extends Transaction implements js_library.JSObjectInterfacesDom {
  TransactionImpl.internal_() : super.internal_();
  get runtimeType => Transaction;
  toString() => super.toString();
}
patch class KeyRange {
  factory KeyRange._internalWrap() => new KeyRangeImpl.internal_();

}
class KeyRangeImpl extends KeyRange implements js_library.JSObjectInterfacesDom {
  KeyRangeImpl.internal_() : super.internal_();
  get runtimeType => KeyRange;
  toString() => super.toString();
}
patch class Request {
  factory Request._internalWrap() => new RequestImpl.internal_();

}
class RequestImpl extends Request implements js_library.JSObjectInterfacesDom {
  RequestImpl.internal_() : super.internal_();
  get runtimeType => Request;
  toString() => super.toString();
}
patch class OpenDBRequest {
  factory OpenDBRequest._internalWrap() => new OpenDBRequestImpl.internal_();

}
class OpenDBRequestImpl extends OpenDBRequest implements js_library.JSObjectInterfacesDom {
  OpenDBRequestImpl.internal_() : super.internal_();
  get runtimeType => OpenDBRequest;
  toString() => super.toString();
}
patch class Database {
  factory Database._internalWrap() => new DatabaseImpl.internal_();

}
class DatabaseImpl extends Database implements js_library.JSObjectInterfacesDom {
  DatabaseImpl.internal_() : super.internal_();
  get runtimeType => Database;
  toString() => super.toString();
}
patch class Index {
  factory Index._internalWrap() => new IndexImpl.internal_();

}
class IndexImpl extends Index implements js_library.JSObjectInterfacesDom {
  IndexImpl.internal_() : super.internal_();
  get runtimeType => Index;
  toString() => super.toString();
}
patch class ObjectStore {
  factory ObjectStore._internalWrap() => new ObjectStoreImpl.internal_();

}
class ObjectStoreImpl extends ObjectStore implements js_library.JSObjectInterfacesDom {
  ObjectStoreImpl.internal_() : super.internal_();
  get runtimeType => ObjectStore;
  toString() => super.toString();
}
patch class VersionChangeEvent {
  factory VersionChangeEvent._internalWrap() => new VersionChangeEventImpl.internal_();

}
class VersionChangeEventImpl extends VersionChangeEvent implements js_library.JSObjectInterfacesDom {
  VersionChangeEventImpl.internal_() : super.internal_();
  get runtimeType => VersionChangeEvent;
  toString() => super.toString();
}
patch class CursorWithValue {
  factory CursorWithValue._internalWrap() => new CursorWithValueImpl.internal_();

}
class CursorWithValueImpl extends CursorWithValue implements js_library.JSObjectInterfacesDom {
  CursorWithValueImpl.internal_() : super.internal_();
  get runtimeType => CursorWithValue;
  toString() => super.toString();
}

"""],"dart:web_gl": ["dart:web_gl", "dart:web_gl_js_interop_patch.dart", """import 'dart:js' as js_library;

/**
 * Placeholder object for cases where we need to determine exactly how many
 * args were passed to a function.
 */
const _UNDEFINED_JS_CONST = const Object();

patch class Buffer {
  factory Buffer._internalWrap() => new BufferImpl.internal_();

}
class BufferImpl extends Buffer implements js_library.JSObjectInterfacesDom {
  BufferImpl.internal_() : super.internal_();
  get runtimeType => Buffer;
  toString() => super.toString();
}
patch class Texture {
  factory Texture._internalWrap() => new TextureImpl.internal_();

}
class TextureImpl extends Texture implements js_library.JSObjectInterfacesDom {
  TextureImpl.internal_() : super.internal_();
  get runtimeType => Texture;
  toString() => super.toString();
}
patch class VertexArrayObjectOes {
  factory VertexArrayObjectOes._internalWrap() => new VertexArrayObjectOesImpl.internal_();

}
class VertexArrayObjectOesImpl extends VertexArrayObjectOes implements js_library.JSObjectInterfacesDom {
  VertexArrayObjectOesImpl.internal_() : super.internal_();
  get runtimeType => VertexArrayObjectOes;
  toString() => super.toString();
}
patch class DepthTexture {
  factory DepthTexture._internalWrap() => new DepthTextureImpl.internal_();

}
class DepthTextureImpl extends DepthTexture implements js_library.JSObjectInterfacesDom {
  DepthTextureImpl.internal_() : super.internal_();
  get runtimeType => DepthTexture;
  toString() => super.toString();
}
patch class OesTextureHalfFloatLinear {
  factory OesTextureHalfFloatLinear._internalWrap() => new OesTextureHalfFloatLinearImpl.internal_();

}
class OesTextureHalfFloatLinearImpl extends OesTextureHalfFloatLinear implements js_library.JSObjectInterfacesDom {
  OesTextureHalfFloatLinearImpl.internal_() : super.internal_();
  get runtimeType => OesTextureHalfFloatLinear;
  toString() => super.toString();
}
patch class Sampler {
  factory Sampler._internalWrap() => new SamplerImpl.internal_();

}
class SamplerImpl extends Sampler implements js_library.JSObjectInterfacesDom {
  SamplerImpl.internal_() : super.internal_();
  get runtimeType => Sampler;
  toString() => super.toString();
}
patch class Sync {
  factory Sync._internalWrap() => new SyncImpl.internal_();

}
class SyncImpl extends Sync implements js_library.JSObjectInterfacesDom {
  SyncImpl.internal_() : super.internal_();
  get runtimeType => Sync;
  toString() => super.toString();
}
patch class OesVertexArrayObject {
  factory OesVertexArrayObject._internalWrap() => new OesVertexArrayObjectImpl.internal_();

}
class OesVertexArrayObjectImpl extends OesVertexArrayObject implements js_library.JSObjectInterfacesDom {
  OesVertexArrayObjectImpl.internal_() : super.internal_();
  get runtimeType => OesVertexArrayObject;
  toString() => super.toString();
}
patch class CompressedTextureS3TC {
  factory CompressedTextureS3TC._internalWrap() => new CompressedTextureS3TCImpl.internal_();

}
class CompressedTextureS3TCImpl extends CompressedTextureS3TC implements js_library.JSObjectInterfacesDom {
  CompressedTextureS3TCImpl.internal_() : super.internal_();
  get runtimeType => CompressedTextureS3TC;
  toString() => super.toString();
}
patch class ExtFragDepth {
  factory ExtFragDepth._internalWrap() => new ExtFragDepthImpl.internal_();

}
class ExtFragDepthImpl extends ExtFragDepth implements js_library.JSObjectInterfacesDom {
  ExtFragDepthImpl.internal_() : super.internal_();
  get runtimeType => ExtFragDepth;
  toString() => super.toString();
}
patch class Shader {
  factory Shader._internalWrap() => new ShaderImpl.internal_();

}
class ShaderImpl extends Shader implements js_library.JSObjectInterfacesDom {
  ShaderImpl.internal_() : super.internal_();
  get runtimeType => Shader;
  toString() => super.toString();
}
patch class _WebGL2RenderingContextBase {
  factory _WebGL2RenderingContextBase._internalWrap() => new _WebGL2RenderingContextBaseImpl.internal_();

}
class _WebGL2RenderingContextBaseImpl extends _WebGL2RenderingContextBase implements js_library.JSObjectInterfacesDom {
  _WebGL2RenderingContextBaseImpl.internal_() : super.internal_();
  get runtimeType => _WebGL2RenderingContextBase;
  toString() => super.toString();
}
patch class Query {
  factory Query._internalWrap() => new QueryImpl.internal_();

}
class QueryImpl extends Query implements js_library.JSObjectInterfacesDom {
  QueryImpl.internal_() : super.internal_();
  get runtimeType => Query;
  toString() => super.toString();
}
patch class RenderingContext {
  factory RenderingContext._internalWrap() => new RenderingContextImpl.internal_();

}
class RenderingContextImpl extends RenderingContext implements js_library.JSObjectInterfacesDom {
  RenderingContextImpl.internal_() : super.internal_();
  get runtimeType => RenderingContext;
  toString() => super.toString();
}
patch class ShaderPrecisionFormat {
  factory ShaderPrecisionFormat._internalWrap() => new ShaderPrecisionFormatImpl.internal_();

}
class ShaderPrecisionFormatImpl extends ShaderPrecisionFormat implements js_library.JSObjectInterfacesDom {
  ShaderPrecisionFormatImpl.internal_() : super.internal_();
  get runtimeType => ShaderPrecisionFormat;
  toString() => super.toString();
}
patch class OesTextureHalfFloat {
  factory OesTextureHalfFloat._internalWrap() => new OesTextureHalfFloatImpl.internal_();

}
class OesTextureHalfFloatImpl extends OesTextureHalfFloat implements js_library.JSObjectInterfacesDom {
  OesTextureHalfFloatImpl.internal_() : super.internal_();
  get runtimeType => OesTextureHalfFloat;
  toString() => super.toString();
}
patch class ExtTextureFilterAnisotropic {
  factory ExtTextureFilterAnisotropic._internalWrap() => new ExtTextureFilterAnisotropicImpl.internal_();

}
class ExtTextureFilterAnisotropicImpl extends ExtTextureFilterAnisotropic implements js_library.JSObjectInterfacesDom {
  ExtTextureFilterAnisotropicImpl.internal_() : super.internal_();
  get runtimeType => ExtTextureFilterAnisotropic;
  toString() => super.toString();
}
patch class OesTextureFloat {
  factory OesTextureFloat._internalWrap() => new OesTextureFloatImpl.internal_();

}
class OesTextureFloatImpl extends OesTextureFloat implements js_library.JSObjectInterfacesDom {
  OesTextureFloatImpl.internal_() : super.internal_();
  get runtimeType => OesTextureFloat;
  toString() => super.toString();
}
patch class VertexArrayObject {
  factory VertexArrayObject._internalWrap() => new VertexArrayObjectImpl.internal_();

}
class VertexArrayObjectImpl extends VertexArrayObject implements js_library.JSObjectInterfacesDom {
  VertexArrayObjectImpl.internal_() : super.internal_();
  get runtimeType => VertexArrayObject;
  toString() => super.toString();
}
patch class CompressedTexturePvrtc {
  factory CompressedTexturePvrtc._internalWrap() => new CompressedTexturePvrtcImpl.internal_();

}
class CompressedTexturePvrtcImpl extends CompressedTexturePvrtc implements js_library.JSObjectInterfacesDom {
  CompressedTexturePvrtcImpl.internal_() : super.internal_();
  get runtimeType => CompressedTexturePvrtc;
  toString() => super.toString();
}
patch class ChromiumSubscribeUniform {
  factory ChromiumSubscribeUniform._internalWrap() => new ChromiumSubscribeUniformImpl.internal_();

}
class ChromiumSubscribeUniformImpl extends ChromiumSubscribeUniform implements js_library.JSObjectInterfacesDom {
  ChromiumSubscribeUniformImpl.internal_() : super.internal_();
  get runtimeType => ChromiumSubscribeUniform;
  toString() => super.toString();
}
patch class _WebGLRenderingContextBase {
  factory _WebGLRenderingContextBase._internalWrap() => new _WebGLRenderingContextBaseImpl.internal_();

}
class _WebGLRenderingContextBaseImpl extends _WebGLRenderingContextBase implements js_library.JSObjectInterfacesDom {
  _WebGLRenderingContextBaseImpl.internal_() : super.internal_();
  get runtimeType => _WebGLRenderingContextBase;
  toString() => super.toString();
}
patch class ActiveInfo {
  factory ActiveInfo._internalWrap() => new ActiveInfoImpl.internal_();

}
class ActiveInfoImpl extends ActiveInfo implements js_library.JSObjectInterfacesDom {
  ActiveInfoImpl.internal_() : super.internal_();
  get runtimeType => ActiveInfo;
  toString() => super.toString();
}
patch class TransformFeedback {
  factory TransformFeedback._internalWrap() => new TransformFeedbackImpl.internal_();

}
class TransformFeedbackImpl extends TransformFeedback implements js_library.JSObjectInterfacesDom {
  TransformFeedbackImpl.internal_() : super.internal_();
  get runtimeType => TransformFeedback;
  toString() => super.toString();
}
patch class ExtShaderTextureLod {
  factory ExtShaderTextureLod._internalWrap() => new ExtShaderTextureLodImpl.internal_();

}
class ExtShaderTextureLodImpl extends ExtShaderTextureLod implements js_library.JSObjectInterfacesDom {
  ExtShaderTextureLodImpl.internal_() : super.internal_();
  get runtimeType => ExtShaderTextureLod;
  toString() => super.toString();
}
patch class UniformLocation {
  factory UniformLocation._internalWrap() => new UniformLocationImpl.internal_();

}
class UniformLocationImpl extends UniformLocation implements js_library.JSObjectInterfacesDom {
  UniformLocationImpl.internal_() : super.internal_();
  get runtimeType => UniformLocation;
  toString() => super.toString();
}
patch class ExtBlendMinMax {
  factory ExtBlendMinMax._internalWrap() => new ExtBlendMinMaxImpl.internal_();

}
class ExtBlendMinMaxImpl extends ExtBlendMinMax implements js_library.JSObjectInterfacesDom {
  ExtBlendMinMaxImpl.internal_() : super.internal_();
  get runtimeType => ExtBlendMinMax;
  toString() => super.toString();
}
patch class Framebuffer {
  factory Framebuffer._internalWrap() => new FramebufferImpl.internal_();

}
class FramebufferImpl extends Framebuffer implements js_library.JSObjectInterfacesDom {
  FramebufferImpl.internal_() : super.internal_();
  get runtimeType => Framebuffer;
  toString() => super.toString();
}
patch class OesStandardDerivatives {
  factory OesStandardDerivatives._internalWrap() => new OesStandardDerivativesImpl.internal_();

}
class OesStandardDerivativesImpl extends OesStandardDerivatives implements js_library.JSObjectInterfacesDom {
  OesStandardDerivativesImpl.internal_() : super.internal_();
  get runtimeType => OesStandardDerivatives;
  toString() => super.toString();
}
patch class DrawBuffers {
  factory DrawBuffers._internalWrap() => new DrawBuffersImpl.internal_();

}
class DrawBuffersImpl extends DrawBuffers implements js_library.JSObjectInterfacesDom {
  DrawBuffersImpl.internal_() : super.internal_();
  get runtimeType => DrawBuffers;
  toString() => super.toString();
}
patch class OesTextureFloatLinear {
  factory OesTextureFloatLinear._internalWrap() => new OesTextureFloatLinearImpl.internal_();

}
class OesTextureFloatLinearImpl extends OesTextureFloatLinear implements js_library.JSObjectInterfacesDom {
  OesTextureFloatLinearImpl.internal_() : super.internal_();
  get runtimeType => OesTextureFloatLinear;
  toString() => super.toString();
}
patch class DebugShaders {
  factory DebugShaders._internalWrap() => new DebugShadersImpl.internal_();

}
class DebugShadersImpl extends DebugShaders implements js_library.JSObjectInterfacesDom {
  DebugShadersImpl.internal_() : super.internal_();
  get runtimeType => DebugShaders;
  toString() => super.toString();
}
patch class Program {
  factory Program._internalWrap() => new ProgramImpl.internal_();

}
class ProgramImpl extends Program implements js_library.JSObjectInterfacesDom {
  ProgramImpl.internal_() : super.internal_();
  get runtimeType => Program;
  toString() => super.toString();
}
patch class ContextEvent {
  factory ContextEvent._internalWrap() => new ContextEventImpl.internal_();

}
class ContextEventImpl extends ContextEvent implements js_library.JSObjectInterfacesDom {
  ContextEventImpl.internal_() : super.internal_();
  get runtimeType => ContextEvent;
  toString() => super.toString();
}
patch class AngleInstancedArrays {
  factory AngleInstancedArrays._internalWrap() => new AngleInstancedArraysImpl.internal_();

}
class AngleInstancedArraysImpl extends AngleInstancedArrays implements js_library.JSObjectInterfacesDom {
  AngleInstancedArraysImpl.internal_() : super.internal_();
  get runtimeType => AngleInstancedArrays;
  toString() => super.toString();
}
patch class DebugRendererInfo {
  factory DebugRendererInfo._internalWrap() => new DebugRendererInfoImpl.internal_();

}
class DebugRendererInfoImpl extends DebugRendererInfo implements js_library.JSObjectInterfacesDom {
  DebugRendererInfoImpl.internal_() : super.internal_();
  get runtimeType => DebugRendererInfo;
  toString() => super.toString();
}
patch class CompressedTextureAtc {
  factory CompressedTextureAtc._internalWrap() => new CompressedTextureAtcImpl.internal_();

}
class CompressedTextureAtcImpl extends CompressedTextureAtc implements js_library.JSObjectInterfacesDom {
  CompressedTextureAtcImpl.internal_() : super.internal_();
  get runtimeType => CompressedTextureAtc;
  toString() => super.toString();
}
patch class OesElementIndexUint {
  factory OesElementIndexUint._internalWrap() => new OesElementIndexUintImpl.internal_();

}
class OesElementIndexUintImpl extends OesElementIndexUint implements js_library.JSObjectInterfacesDom {
  OesElementIndexUintImpl.internal_() : super.internal_();
  get runtimeType => OesElementIndexUint;
  toString() => super.toString();
}
patch class CompressedTextureETC1 {
  factory CompressedTextureETC1._internalWrap() => new CompressedTextureETC1Impl.internal_();

}
class CompressedTextureETC1Impl extends CompressedTextureETC1 implements js_library.JSObjectInterfacesDom {
  CompressedTextureETC1Impl.internal_() : super.internal_();
  get runtimeType => CompressedTextureETC1;
  toString() => super.toString();
}
patch class LoseContext {
  factory LoseContext._internalWrap() => new LoseContextImpl.internal_();

}
class LoseContextImpl extends LoseContext implements js_library.JSObjectInterfacesDom {
  LoseContextImpl.internal_() : super.internal_();
  get runtimeType => LoseContext;
  toString() => super.toString();
}
patch class Renderbuffer {
  factory Renderbuffer._internalWrap() => new RenderbufferImpl.internal_();

}
class RenderbufferImpl extends Renderbuffer implements js_library.JSObjectInterfacesDom {
  RenderbufferImpl.internal_() : super.internal_();
  get runtimeType => Renderbuffer;
  toString() => super.toString();
}
patch class RenderingContext2 {
  factory RenderingContext2._internalWrap() => new RenderingContext2Impl.internal_();

}
class RenderingContext2Impl extends RenderingContext2 implements js_library.JSObjectInterfacesDom {
  RenderingContext2Impl.internal_() : super.internal_();
  get runtimeType => RenderingContext2;
  toString() => super.toString();
}
patch class EXTsRgb {
  factory EXTsRgb._internalWrap() => new EXTsRgbImpl.internal_();

}
class EXTsRgbImpl extends EXTsRgb implements js_library.JSObjectInterfacesDom {
  EXTsRgbImpl.internal_() : super.internal_();
  get runtimeType => EXTsRgb;
  toString() => super.toString();
}

"""],"dart:web_sql": ["dart:web_sql", "dart:web_sql_js_interop_patch.dart", """import 'dart:js' as js_library;

/**
 * Placeholder object for cases where we need to determine exactly how many
 * args were passed to a function.
 */
const _UNDEFINED_JS_CONST = const Object();

patch class SqlError {
  factory SqlError._internalWrap() => new SqlErrorImpl.internal_();

}
class SqlErrorImpl extends SqlError implements js_library.JSObjectInterfacesDom {
  SqlErrorImpl.internal_() : super.internal_();
  get runtimeType => SqlError;
  toString() => super.toString();
}
patch class SqlResultSet {
  factory SqlResultSet._internalWrap() => new SqlResultSetImpl.internal_();

}
class SqlResultSetImpl extends SqlResultSet implements js_library.JSObjectInterfacesDom {
  SqlResultSetImpl.internal_() : super.internal_();
  get runtimeType => SqlResultSet;
  toString() => super.toString();
}
patch class SqlResultSetRowList {
  factory SqlResultSetRowList._internalWrap() => new SqlResultSetRowListImpl.internal_();

}
class SqlResultSetRowListImpl extends SqlResultSetRowList implements js_library.JSObjectInterfacesDom {
  SqlResultSetRowListImpl.internal_() : super.internal_();
  get runtimeType => SqlResultSetRowList;
  toString() => super.toString();
}
patch class SqlDatabase {
  factory SqlDatabase._internalWrap() => new SqlDatabaseImpl.internal_();

}
class SqlDatabaseImpl extends SqlDatabase implements js_library.JSObjectInterfacesDom {
  SqlDatabaseImpl.internal_() : super.internal_();
  get runtimeType => SqlDatabase;
  toString() => super.toString();
}
patch class SqlTransaction {
  factory SqlTransaction._internalWrap() => new SqlTransactionImpl.internal_();

}
class SqlTransactionImpl extends SqlTransaction implements js_library.JSObjectInterfacesDom {
  SqlTransactionImpl.internal_() : super.internal_();
  get runtimeType => SqlTransaction;
  toString() => super.toString();
}

"""],"dart:svg": ["dart:svg", "dart:svg_js_interop_patch.dart", """import 'dart:js' as js_library;

/**
 * Placeholder object for cases where we need to determine exactly how many
 * args were passed to a function.
 */
const _UNDEFINED_JS_CONST = const Object();

patch class AnimatedString {
  factory AnimatedString._internalWrap() => new AnimatedStringImpl.internal_();

}
class AnimatedStringImpl extends AnimatedString implements js_library.JSObjectInterfacesDom {
  AnimatedStringImpl.internal_() : super.internal_();
  get runtimeType => AnimatedString;
  toString() => super.toString();
}
patch class FilterElement {
  factory FilterElement._internalWrap() => new FilterElementImpl.internal_();

}
class FilterElementImpl extends FilterElement implements js_library.JSObjectInterfacesDom {
  FilterElementImpl.internal_() : super.internal_();
  get runtimeType => FilterElement;
  toString() => super.toString();
}
patch class FilterPrimitiveStandardAttributes {
  factory FilterPrimitiveStandardAttributes._internalWrap() => new FilterPrimitiveStandardAttributesImpl.internal_();

}
class FilterPrimitiveStandardAttributesImpl extends FilterPrimitiveStandardAttributes implements js_library.JSObjectInterfacesDom {
  FilterPrimitiveStandardAttributesImpl.internal_() : super.internal_();
  get runtimeType => FilterPrimitiveStandardAttributes;
  toString() => super.toString();
}
patch class PathSegLinetoRel {
  factory PathSegLinetoRel._internalWrap() => new PathSegLinetoRelImpl.internal_();

}
class PathSegLinetoRelImpl extends PathSegLinetoRel implements js_library.JSObjectInterfacesDom {
  PathSegLinetoRelImpl.internal_() : super.internal_();
  get runtimeType => PathSegLinetoRel;
  toString() => super.toString();
}
patch class UriReference {
  factory UriReference._internalWrap() => new UriReferenceImpl.internal_();

}
class UriReferenceImpl extends UriReference implements js_library.JSObjectInterfacesDom {
  UriReferenceImpl.internal_() : super.internal_();
  get runtimeType => UriReference;
  toString() => super.toString();
}
patch class ImageElement {
  factory ImageElement._internalWrap() => new ImageElementImpl.internal_();

}
class ImageElementImpl extends ImageElement implements js_library.JSObjectInterfacesDom {
  ImageElementImpl.internal_() : super.internal_();
  get runtimeType => ImageElement;
  toString() => super.toString();
}
patch class StyleElement {
  factory StyleElement._internalWrap() => new StyleElementImpl.internal_();

}
class StyleElementImpl extends StyleElement implements js_library.JSObjectInterfacesDom {
  StyleElementImpl.internal_() : super.internal_();
  get runtimeType => StyleElement;
  toString() => super.toString();
}
patch class AnimatedPreserveAspectRatio {
  factory AnimatedPreserveAspectRatio._internalWrap() => new AnimatedPreserveAspectRatioImpl.internal_();

}
class AnimatedPreserveAspectRatioImpl extends AnimatedPreserveAspectRatio implements js_library.JSObjectInterfacesDom {
  AnimatedPreserveAspectRatioImpl.internal_() : super.internal_();
  get runtimeType => AnimatedPreserveAspectRatio;
  toString() => super.toString();
}
patch class TextElement {
  factory TextElement._internalWrap() => new TextElementImpl.internal_();

}
class TextElementImpl extends TextElement implements js_library.JSObjectInterfacesDom {
  TextElementImpl.internal_() : super.internal_();
  get runtimeType => TextElement;
  toString() => super.toString();
}
patch class DefsElement {
  factory DefsElement._internalWrap() => new DefsElementImpl.internal_();

}
class DefsElementImpl extends DefsElement implements js_library.JSObjectInterfacesDom {
  DefsElementImpl.internal_() : super.internal_();
  get runtimeType => DefsElement;
  toString() => super.toString();
}
patch class FEDiffuseLightingElement {
  factory FEDiffuseLightingElement._internalWrap() => new FEDiffuseLightingElementImpl.internal_();

}
class FEDiffuseLightingElementImpl extends FEDiffuseLightingElement implements js_library.JSObjectInterfacesDom {
  FEDiffuseLightingElementImpl.internal_() : super.internal_();
  get runtimeType => FEDiffuseLightingElement;
  toString() => super.toString();
}
patch class FETileElement {
  factory FETileElement._internalWrap() => new FETileElementImpl.internal_();

}
class FETileElementImpl extends FETileElement implements js_library.JSObjectInterfacesDom {
  FETileElementImpl.internal_() : super.internal_();
  get runtimeType => FETileElement;
  toString() => super.toString();
}
patch class PathSegLinetoHorizontalAbs {
  factory PathSegLinetoHorizontalAbs._internalWrap() => new PathSegLinetoHorizontalAbsImpl.internal_();

}
class PathSegLinetoHorizontalAbsImpl extends PathSegLinetoHorizontalAbs implements js_library.JSObjectInterfacesDom {
  PathSegLinetoHorizontalAbsImpl.internal_() : super.internal_();
  get runtimeType => PathSegLinetoHorizontalAbs;
  toString() => super.toString();
}
patch class PathSegMovetoRel {
  factory PathSegMovetoRel._internalWrap() => new PathSegMovetoRelImpl.internal_();

}
class PathSegMovetoRelImpl extends PathSegMovetoRel implements js_library.JSObjectInterfacesDom {
  PathSegMovetoRelImpl.internal_() : super.internal_();
  get runtimeType => PathSegMovetoRel;
  toString() => super.toString();
}
patch class _SVGFEDropShadowElement {
  factory _SVGFEDropShadowElement._internalWrap() => new _SVGFEDropShadowElementImpl.internal_();

}
class _SVGFEDropShadowElementImpl extends _SVGFEDropShadowElement implements js_library.JSObjectInterfacesDom {
  _SVGFEDropShadowElementImpl.internal_() : super.internal_();
  get runtimeType => _SVGFEDropShadowElement;
  toString() => super.toString();
}
patch class Transform {
  factory Transform._internalWrap() => new TransformImpl.internal_();

}
class TransformImpl extends Transform implements js_library.JSObjectInterfacesDom {
  TransformImpl.internal_() : super.internal_();
  get runtimeType => Transform;
  toString() => super.toString();
}
patch class PathSegArcRel {
  factory PathSegArcRel._internalWrap() => new PathSegArcRelImpl.internal_();

}
class PathSegArcRelImpl extends PathSegArcRel implements js_library.JSObjectInterfacesDom {
  PathSegArcRelImpl.internal_() : super.internal_();
  get runtimeType => PathSegArcRel;
  toString() => super.toString();
}
patch class AnimateElement {
  factory AnimateElement._internalWrap() => new AnimateElementImpl.internal_();

}
class AnimateElementImpl extends AnimateElement implements js_library.JSObjectInterfacesDom {
  AnimateElementImpl.internal_() : super.internal_();
  get runtimeType => AnimateElement;
  toString() => super.toString();
}
patch class PolylineElement {
  factory PolylineElement._internalWrap() => new PolylineElementImpl.internal_();

}
class PolylineElementImpl extends PolylineElement implements js_library.JSObjectInterfacesDom {
  PolylineElementImpl.internal_() : super.internal_();
  get runtimeType => PolylineElement;
  toString() => super.toString();
}
patch class AnimatedRect {
  factory AnimatedRect._internalWrap() => new AnimatedRectImpl.internal_();

}
class AnimatedRectImpl extends AnimatedRect implements js_library.JSObjectInterfacesDom {
  AnimatedRectImpl.internal_() : super.internal_();
  get runtimeType => AnimatedRect;
  toString() => super.toString();
}
patch class GraphicsElement {
  factory GraphicsElement._internalWrap() => new GraphicsElementImpl.internal_();

}
class GraphicsElementImpl extends GraphicsElement implements js_library.JSObjectInterfacesDom {
  GraphicsElementImpl.internal_() : super.internal_();
  get runtimeType => GraphicsElement;
  toString() => super.toString();
}
patch class TransformList {
  factory TransformList._internalWrap() => new TransformListImpl.internal_();

}
class TransformListImpl extends TransformList implements js_library.JSObjectInterfacesDom {
  TransformListImpl.internal_() : super.internal_();
  get runtimeType => TransformList;
  toString() => super.toString();
}
patch class EllipseElement {
  factory EllipseElement._internalWrap() => new EllipseElementImpl.internal_();

}
class EllipseElementImpl extends EllipseElement implements js_library.JSObjectInterfacesDom {
  EllipseElementImpl.internal_() : super.internal_();
  get runtimeType => EllipseElement;
  toString() => super.toString();
}
patch class FEFuncGElement {
  factory FEFuncGElement._internalWrap() => new FEFuncGElementImpl.internal_();

}
class FEFuncGElementImpl extends FEFuncGElement implements js_library.JSObjectInterfacesDom {
  FEFuncGElementImpl.internal_() : super.internal_();
  get runtimeType => FEFuncGElement;
  toString() => super.toString();
}
patch class PointList {
  factory PointList._internalWrap() => new PointListImpl.internal_();

}
class PointListImpl extends PointList implements js_library.JSObjectInterfacesDom {
  PointListImpl.internal_() : super.internal_();
  get runtimeType => PointList;
  toString() => super.toString();
}
patch class FEMergeElement {
  factory FEMergeElement._internalWrap() => new FEMergeElementImpl.internal_();

}
class FEMergeElementImpl extends FEMergeElement implements js_library.JSObjectInterfacesDom {
  FEMergeElementImpl.internal_() : super.internal_();
  get runtimeType => FEMergeElement;
  toString() => super.toString();
}
patch class CircleElement {
  factory CircleElement._internalWrap() => new CircleElementImpl.internal_();

}
class CircleElementImpl extends CircleElement implements js_library.JSObjectInterfacesDom {
  CircleElementImpl.internal_() : super.internal_();
  get runtimeType => CircleElement;
  toString() => super.toString();
}
patch class AnimatedNumberList {
  factory AnimatedNumberList._internalWrap() => new AnimatedNumberListImpl.internal_();

}
class AnimatedNumberListImpl extends AnimatedNumberList implements js_library.JSObjectInterfacesDom {
  AnimatedNumberListImpl.internal_() : super.internal_();
  get runtimeType => AnimatedNumberList;
  toString() => super.toString();
}
patch class SwitchElement {
  factory SwitchElement._internalWrap() => new SwitchElementImpl.internal_();

}
class SwitchElementImpl extends SwitchElement implements js_library.JSObjectInterfacesDom {
  SwitchElementImpl.internal_() : super.internal_();
  get runtimeType => SwitchElement;
  toString() => super.toString();
}
patch class RadialGradientElement {
  factory RadialGradientElement._internalWrap() => new RadialGradientElementImpl.internal_();

}
class RadialGradientElementImpl extends RadialGradientElement implements js_library.JSObjectInterfacesDom {
  RadialGradientElementImpl.internal_() : super.internal_();
  get runtimeType => RadialGradientElement;
  toString() => super.toString();
}
patch class FEDistantLightElement {
  factory FEDistantLightElement._internalWrap() => new FEDistantLightElementImpl.internal_();

}
class FEDistantLightElementImpl extends FEDistantLightElement implements js_library.JSObjectInterfacesDom {
  FEDistantLightElementImpl.internal_() : super.internal_();
  get runtimeType => FEDistantLightElement;
  toString() => super.toString();
}
patch class LinearGradientElement {
  factory LinearGradientElement._internalWrap() => new LinearGradientElementImpl.internal_();

}
class LinearGradientElementImpl extends LinearGradientElement implements js_library.JSObjectInterfacesDom {
  LinearGradientElementImpl.internal_() : super.internal_();
  get runtimeType => LinearGradientElement;
  toString() => super.toString();
}
patch class TextPositioningElement {
  factory TextPositioningElement._internalWrap() => new TextPositioningElementImpl.internal_();

}
class TextPositioningElementImpl extends TextPositioningElement implements js_library.JSObjectInterfacesDom {
  TextPositioningElementImpl.internal_() : super.internal_();
  get runtimeType => TextPositioningElement;
  toString() => super.toString();
}
patch class PathSegCurvetoQuadraticRel {
  factory PathSegCurvetoQuadraticRel._internalWrap() => new PathSegCurvetoQuadraticRelImpl.internal_();

}
class PathSegCurvetoQuadraticRelImpl extends PathSegCurvetoQuadraticRel implements js_library.JSObjectInterfacesDom {
  PathSegCurvetoQuadraticRelImpl.internal_() : super.internal_();
  get runtimeType => PathSegCurvetoQuadraticRel;
  toString() => super.toString();
}
patch class PathSegLinetoHorizontalRel {
  factory PathSegLinetoHorizontalRel._internalWrap() => new PathSegLinetoHorizontalRelImpl.internal_();

}
class PathSegLinetoHorizontalRelImpl extends PathSegLinetoHorizontalRel implements js_library.JSObjectInterfacesDom {
  PathSegLinetoHorizontalRelImpl.internal_() : super.internal_();
  get runtimeType => PathSegLinetoHorizontalRel;
  toString() => super.toString();
}
patch class StringList {
  factory StringList._internalWrap() => new StringListImpl.internal_();

}
class StringListImpl extends StringList implements js_library.JSObjectInterfacesDom {
  StringListImpl.internal_() : super.internal_();
  get runtimeType => StringList;
  toString() => super.toString();
}
patch class TextContentElement {
  factory TextContentElement._internalWrap() => new TextContentElementImpl.internal_();

}
class TextContentElementImpl extends TextContentElement implements js_library.JSObjectInterfacesDom {
  TextContentElementImpl.internal_() : super.internal_();
  get runtimeType => TextContentElement;
  toString() => super.toString();
}
patch class FEConvolveMatrixElement {
  factory FEConvolveMatrixElement._internalWrap() => new FEConvolveMatrixElementImpl.internal_();

}
class FEConvolveMatrixElementImpl extends FEConvolveMatrixElement implements js_library.JSObjectInterfacesDom {
  FEConvolveMatrixElementImpl.internal_() : super.internal_();
  get runtimeType => FEConvolveMatrixElement;
  toString() => super.toString();
}
patch class PathSegLinetoAbs {
  factory PathSegLinetoAbs._internalWrap() => new PathSegLinetoAbsImpl.internal_();

}
class PathSegLinetoAbsImpl extends PathSegLinetoAbs implements js_library.JSObjectInterfacesDom {
  PathSegLinetoAbsImpl.internal_() : super.internal_();
  get runtimeType => PathSegLinetoAbs;
  toString() => super.toString();
}
patch class FESpecularLightingElement {
  factory FESpecularLightingElement._internalWrap() => new FESpecularLightingElementImpl.internal_();

}
class FESpecularLightingElementImpl extends FESpecularLightingElement implements js_library.JSObjectInterfacesDom {
  FESpecularLightingElementImpl.internal_() : super.internal_();
  get runtimeType => FESpecularLightingElement;
  toString() => super.toString();
}
patch class AnimatedTransformList {
  factory AnimatedTransformList._internalWrap() => new AnimatedTransformListImpl.internal_();

}
class AnimatedTransformListImpl extends AnimatedTransformList implements js_library.JSObjectInterfacesDom {
  AnimatedTransformListImpl.internal_() : super.internal_();
  get runtimeType => AnimatedTransformList;
  toString() => super.toString();
}
patch class FEGaussianBlurElement {
  factory FEGaussianBlurElement._internalWrap() => new FEGaussianBlurElementImpl.internal_();

}
class FEGaussianBlurElementImpl extends FEGaussianBlurElement implements js_library.JSObjectInterfacesDom {
  FEGaussianBlurElementImpl.internal_() : super.internal_();
  get runtimeType => FEGaussianBlurElement;
  toString() => super.toString();
}
patch class Number {
  factory Number._internalWrap() => new NumberImpl.internal_();

}
class NumberImpl extends Number implements js_library.JSObjectInterfacesDom {
  NumberImpl.internal_() : super.internal_();
  get runtimeType => Number;
  toString() => super.toString();
}
patch class ZoomEvent {
  factory ZoomEvent._internalWrap() => new ZoomEventImpl.internal_();

}
class ZoomEventImpl extends ZoomEvent implements js_library.JSObjectInterfacesDom {
  ZoomEventImpl.internal_() : super.internal_();
  get runtimeType => ZoomEvent;
  toString() => super.toString();
}
patch class PathSegCurvetoCubicSmoothAbs {
  factory PathSegCurvetoCubicSmoothAbs._internalWrap() => new PathSegCurvetoCubicSmoothAbsImpl.internal_();

}
class PathSegCurvetoCubicSmoothAbsImpl extends PathSegCurvetoCubicSmoothAbs implements js_library.JSObjectInterfacesDom {
  PathSegCurvetoCubicSmoothAbsImpl.internal_() : super.internal_();
  get runtimeType => PathSegCurvetoCubicSmoothAbs;
  toString() => super.toString();
}
patch class AnimatedNumber {
  factory AnimatedNumber._internalWrap() => new AnimatedNumberImpl.internal_();

}
class AnimatedNumberImpl extends AnimatedNumber implements js_library.JSObjectInterfacesDom {
  AnimatedNumberImpl.internal_() : super.internal_();
  get runtimeType => AnimatedNumber;
  toString() => super.toString();
}
patch class MaskElement {
  factory MaskElement._internalWrap() => new MaskElementImpl.internal_();

}
class MaskElementImpl extends MaskElement implements js_library.JSObjectInterfacesDom {
  MaskElementImpl.internal_() : super.internal_();
  get runtimeType => MaskElement;
  toString() => super.toString();
}
patch class Angle {
  factory Angle._internalWrap() => new AngleImpl.internal_();

}
class AngleImpl extends Angle implements js_library.JSObjectInterfacesDom {
  AngleImpl.internal_() : super.internal_();
  get runtimeType => Angle;
  toString() => super.toString();
}
patch class SymbolElement {
  factory SymbolElement._internalWrap() => new SymbolElementImpl.internal_();

}
class SymbolElementImpl extends SymbolElement implements js_library.JSObjectInterfacesDom {
  SymbolElementImpl.internal_() : super.internal_();
  get runtimeType => SymbolElement;
  toString() => super.toString();
}
patch class PathSegArcAbs {
  factory PathSegArcAbs._internalWrap() => new PathSegArcAbsImpl.internal_();

}
class PathSegArcAbsImpl extends PathSegArcAbs implements js_library.JSObjectInterfacesDom {
  PathSegArcAbsImpl.internal_() : super.internal_();
  get runtimeType => PathSegArcAbs;
  toString() => super.toString();
}
patch class RectElement {
  factory RectElement._internalWrap() => new RectElementImpl.internal_();

}
class RectElementImpl extends RectElement implements js_library.JSObjectInterfacesDom {
  RectElementImpl.internal_() : super.internal_();
  get runtimeType => RectElement;
  toString() => super.toString();
}
patch class FEFloodElement {
  factory FEFloodElement._internalWrap() => new FEFloodElementImpl.internal_();

}
class FEFloodElementImpl extends FEFloodElement implements js_library.JSObjectInterfacesDom {
  FEFloodElementImpl.internal_() : super.internal_();
  get runtimeType => FEFloodElement;
  toString() => super.toString();
}
patch class PathSegCurvetoQuadraticAbs {
  factory PathSegCurvetoQuadraticAbs._internalWrap() => new PathSegCurvetoQuadraticAbsImpl.internal_();

}
class PathSegCurvetoQuadraticAbsImpl extends PathSegCurvetoQuadraticAbs implements js_library.JSObjectInterfacesDom {
  PathSegCurvetoQuadraticAbsImpl.internal_() : super.internal_();
  get runtimeType => PathSegCurvetoQuadraticAbs;
  toString() => super.toString();
}
patch class ScriptElement {
  factory ScriptElement._internalWrap() => new ScriptElementImpl.internal_();

}
class ScriptElementImpl extends ScriptElement implements js_library.JSObjectInterfacesDom {
  ScriptElementImpl.internal_() : super.internal_();
  get runtimeType => ScriptElement;
  toString() => super.toString();
}
patch class AnimatedInteger {
  factory AnimatedInteger._internalWrap() => new AnimatedIntegerImpl.internal_();

}
class AnimatedIntegerImpl extends AnimatedInteger implements js_library.JSObjectInterfacesDom {
  AnimatedIntegerImpl.internal_() : super.internal_();
  get runtimeType => AnimatedInteger;
  toString() => super.toString();
}
patch class Tests {
  factory Tests._internalWrap() => new TestsImpl.internal_();

}
class TestsImpl extends Tests implements js_library.JSObjectInterfacesDom {
  TestsImpl.internal_() : super.internal_();
  get runtimeType => Tests;
  toString() => super.toString();
}
patch class PathSegCurvetoCubicSmoothRel {
  factory PathSegCurvetoCubicSmoothRel._internalWrap() => new PathSegCurvetoCubicSmoothRelImpl.internal_();

}
class PathSegCurvetoCubicSmoothRelImpl extends PathSegCurvetoCubicSmoothRel implements js_library.JSObjectInterfacesDom {
  PathSegCurvetoCubicSmoothRelImpl.internal_() : super.internal_();
  get runtimeType => PathSegCurvetoCubicSmoothRel;
  toString() => super.toString();
}
patch class PathSeg {
  factory PathSeg._internalWrap() => new PathSegImpl.internal_();

}
class PathSegImpl extends PathSeg implements js_library.JSObjectInterfacesDom {
  PathSegImpl.internal_() : super.internal_();
  get runtimeType => PathSeg;
  toString() => super.toString();
}
patch class GElement {
  factory GElement._internalWrap() => new GElementImpl.internal_();

}
class GElementImpl extends GElement implements js_library.JSObjectInterfacesDom {
  GElementImpl.internal_() : super.internal_();
  get runtimeType => GElement;
  toString() => super.toString();
}
patch class PathSegMovetoAbs {
  factory PathSegMovetoAbs._internalWrap() => new PathSegMovetoAbsImpl.internal_();

}
class PathSegMovetoAbsImpl extends PathSegMovetoAbs implements js_library.JSObjectInterfacesDom {
  PathSegMovetoAbsImpl.internal_() : super.internal_();
  get runtimeType => PathSegMovetoAbs;
  toString() => super.toString();
}
patch class PathSegCurvetoCubicAbs {
  factory PathSegCurvetoCubicAbs._internalWrap() => new PathSegCurvetoCubicAbsImpl.internal_();

}
class PathSegCurvetoCubicAbsImpl extends PathSegCurvetoCubicAbs implements js_library.JSObjectInterfacesDom {
  PathSegCurvetoCubicAbsImpl.internal_() : super.internal_();
  get runtimeType => PathSegCurvetoCubicAbs;
  toString() => super.toString();
}
patch class AnimatedEnumeration {
  factory AnimatedEnumeration._internalWrap() => new AnimatedEnumerationImpl.internal_();

}
class AnimatedEnumerationImpl extends AnimatedEnumeration implements js_library.JSObjectInterfacesDom {
  AnimatedEnumerationImpl.internal_() : super.internal_();
  get runtimeType => AnimatedEnumeration;
  toString() => super.toString();
}
patch class TitleElement {
  factory TitleElement._internalWrap() => new TitleElementImpl.internal_();

}
class TitleElementImpl extends TitleElement implements js_library.JSObjectInterfacesDom {
  TitleElementImpl.internal_() : super.internal_();
  get runtimeType => TitleElement;
  toString() => super.toString();
}
patch class MetadataElement {
  factory MetadataElement._internalWrap() => new MetadataElementImpl.internal_();

}
class MetadataElementImpl extends MetadataElement implements js_library.JSObjectInterfacesDom {
  MetadataElementImpl.internal_() : super.internal_();
  get runtimeType => MetadataElement;
  toString() => super.toString();
}
patch class AElement {
  factory AElement._internalWrap() => new AElementImpl.internal_();

}
class AElementImpl extends AElement implements js_library.JSObjectInterfacesDom {
  AElementImpl.internal_() : super.internal_();
  get runtimeType => AElement;
  toString() => super.toString();
}
patch class _GradientElement {
  factory _GradientElement._internalWrap() => new _GradientElementImpl.internal_();

}
class _GradientElementImpl extends _GradientElement implements js_library.JSObjectInterfacesDom {
  _GradientElementImpl.internal_() : super.internal_();
  get runtimeType => _GradientElement;
  toString() => super.toString();
}
patch class FEImageElement {
  factory FEImageElement._internalWrap() => new FEImageElementImpl.internal_();

}
class FEImageElementImpl extends FEImageElement implements js_library.JSObjectInterfacesDom {
  FEImageElementImpl.internal_() : super.internal_();
  get runtimeType => FEImageElement;
  toString() => super.toString();
}
patch class _SVGComponentTransferFunctionElement {
  factory _SVGComponentTransferFunctionElement._internalWrap() => new _SVGComponentTransferFunctionElementImpl.internal_();

}
class _SVGComponentTransferFunctionElementImpl extends _SVGComponentTransferFunctionElement implements js_library.JSObjectInterfacesDom {
  _SVGComponentTransferFunctionElementImpl.internal_() : super.internal_();
  get runtimeType => _SVGComponentTransferFunctionElement;
  toString() => super.toString();
}
patch class PathSegLinetoVerticalRel {
  factory PathSegLinetoVerticalRel._internalWrap() => new PathSegLinetoVerticalRelImpl.internal_();

}
class PathSegLinetoVerticalRelImpl extends PathSegLinetoVerticalRel implements js_library.JSObjectInterfacesDom {
  PathSegLinetoVerticalRelImpl.internal_() : super.internal_();
  get runtimeType => PathSegLinetoVerticalRel;
  toString() => super.toString();
}
patch class AnimatedLengthList {
  factory AnimatedLengthList._internalWrap() => new AnimatedLengthListImpl.internal_();

}
class AnimatedLengthListImpl extends AnimatedLengthList implements js_library.JSObjectInterfacesDom {
  AnimatedLengthListImpl.internal_() : super.internal_();
  get runtimeType => AnimatedLengthList;
  toString() => super.toString();
}
patch class FEMorphologyElement {
  factory FEMorphologyElement._internalWrap() => new FEMorphologyElementImpl.internal_();

}
class FEMorphologyElementImpl extends FEMorphologyElement implements js_library.JSObjectInterfacesDom {
  FEMorphologyElementImpl.internal_() : super.internal_();
  get runtimeType => FEMorphologyElement;
  toString() => super.toString();
}
patch class PolygonElement {
  factory PolygonElement._internalWrap() => new PolygonElementImpl.internal_();

}
class PolygonElementImpl extends PolygonElement implements js_library.JSObjectInterfacesDom {
  PolygonElementImpl.internal_() : super.internal_();
  get runtimeType => PolygonElement;
  toString() => super.toString();
}
patch class UseElement {
  factory UseElement._internalWrap() => new UseElementImpl.internal_();

}
class UseElementImpl extends UseElement implements js_library.JSObjectInterfacesDom {
  UseElementImpl.internal_() : super.internal_();
  get runtimeType => UseElement;
  toString() => super.toString();
}
patch class Point {
  factory Point._internalWrap() => new PointImpl.internal_();

}
class PointImpl extends Point implements js_library.JSObjectInterfacesDom {
  PointImpl.internal_() : super.internal_();
  get runtimeType => Point;
  toString() => super.toString();
}
patch class Rect {
  factory Rect._internalWrap() => new RectImpl.internal_();

}
class RectImpl extends Rect implements js_library.JSObjectInterfacesDom {
  RectImpl.internal_() : super.internal_();
  get runtimeType => Rect;
  toString() => super.toString();
}
patch class AnimatedBoolean {
  factory AnimatedBoolean._internalWrap() => new AnimatedBooleanImpl.internal_();

}
class AnimatedBooleanImpl extends AnimatedBoolean implements js_library.JSObjectInterfacesDom {
  AnimatedBooleanImpl.internal_() : super.internal_();
  get runtimeType => AnimatedBoolean;
  toString() => super.toString();
}
patch class FETurbulenceElement {
  factory FETurbulenceElement._internalWrap() => new FETurbulenceElementImpl.internal_();

}
class FETurbulenceElementImpl extends FETurbulenceElement implements js_library.JSObjectInterfacesDom {
  FETurbulenceElementImpl.internal_() : super.internal_();
  get runtimeType => FETurbulenceElement;
  toString() => super.toString();
}
patch class NumberList {
  factory NumberList._internalWrap() => new NumberListImpl.internal_();

}
class NumberListImpl extends NumberList implements js_library.JSObjectInterfacesDom {
  NumberListImpl.internal_() : super.internal_();
  get runtimeType => NumberList;
  toString() => super.toString();
}
patch class AnimationElement {
  factory AnimationElement._internalWrap() => new AnimationElementImpl.internal_();

}
class AnimationElementImpl extends AnimationElement implements js_library.JSObjectInterfacesDom {
  AnimationElementImpl.internal_() : super.internal_();
  get runtimeType => AnimationElement;
  toString() => super.toString();
}
patch class MarkerElement {
  factory MarkerElement._internalWrap() => new MarkerElementImpl.internal_();

}
class MarkerElementImpl extends MarkerElement implements js_library.JSObjectInterfacesDom {
  MarkerElementImpl.internal_() : super.internal_();
  get runtimeType => MarkerElement;
  toString() => super.toString();
}
patch class FECompositeElement {
  factory FECompositeElement._internalWrap() => new FECompositeElementImpl.internal_();

}
class FECompositeElementImpl extends FECompositeElement implements js_library.JSObjectInterfacesDom {
  FECompositeElementImpl.internal_() : super.internal_();
  get runtimeType => FECompositeElement;
  toString() => super.toString();
}
patch class PathSegList {
  factory PathSegList._internalWrap() => new PathSegListImpl.internal_();

}
class PathSegListImpl extends PathSegList implements js_library.JSObjectInterfacesDom {
  PathSegListImpl.internal_() : super.internal_();
  get runtimeType => PathSegList;
  toString() => super.toString();
}
patch class PathSegCurvetoQuadraticSmoothRel {
  factory PathSegCurvetoQuadraticSmoothRel._internalWrap() => new PathSegCurvetoQuadraticSmoothRelImpl.internal_();

}
class PathSegCurvetoQuadraticSmoothRelImpl extends PathSegCurvetoQuadraticSmoothRel implements js_library.JSObjectInterfacesDom {
  PathSegCurvetoQuadraticSmoothRelImpl.internal_() : super.internal_();
  get runtimeType => PathSegCurvetoQuadraticSmoothRel;
  toString() => super.toString();
}
patch class FEFuncRElement {
  factory FEFuncRElement._internalWrap() => new FEFuncRElementImpl.internal_();

}
class FEFuncRElementImpl extends FEFuncRElement implements js_library.JSObjectInterfacesDom {
  FEFuncRElementImpl.internal_() : super.internal_();
  get runtimeType => FEFuncRElement;
  toString() => super.toString();
}
patch class FEFuncBElement {
  factory FEFuncBElement._internalWrap() => new FEFuncBElementImpl.internal_();

}
class FEFuncBElementImpl extends FEFuncBElement implements js_library.JSObjectInterfacesDom {
  FEFuncBElementImpl.internal_() : super.internal_();
  get runtimeType => FEFuncBElement;
  toString() => super.toString();
}
patch class FEBlendElement {
  factory FEBlendElement._internalWrap() => new FEBlendElementImpl.internal_();

}
class FEBlendElementImpl extends FEBlendElement implements js_library.JSObjectInterfacesDom {
  FEBlendElementImpl.internal_() : super.internal_();
  get runtimeType => FEBlendElement;
  toString() => super.toString();
}
patch class AnimatedAngle {
  factory AnimatedAngle._internalWrap() => new AnimatedAngleImpl.internal_();

}
class AnimatedAngleImpl extends AnimatedAngle implements js_library.JSObjectInterfacesDom {
  AnimatedAngleImpl.internal_() : super.internal_();
  get runtimeType => AnimatedAngle;
  toString() => super.toString();
}
patch class TSpanElement {
  factory TSpanElement._internalWrap() => new TSpanElementImpl.internal_();

}
class TSpanElementImpl extends TSpanElement implements js_library.JSObjectInterfacesDom {
  TSpanElementImpl.internal_() : super.internal_();
  get runtimeType => TSpanElement;
  toString() => super.toString();
}
patch class PathSegCurvetoCubicRel {
  factory PathSegCurvetoCubicRel._internalWrap() => new PathSegCurvetoCubicRelImpl.internal_();

}
class PathSegCurvetoCubicRelImpl extends PathSegCurvetoCubicRel implements js_library.JSObjectInterfacesDom {
  PathSegCurvetoCubicRelImpl.internal_() : super.internal_();
  get runtimeType => PathSegCurvetoCubicRel;
  toString() => super.toString();
}
patch class AnimateMotionElement {
  factory AnimateMotionElement._internalWrap() => new AnimateMotionElementImpl.internal_();

}
class AnimateMotionElementImpl extends AnimateMotionElement implements js_library.JSObjectInterfacesDom {
  AnimateMotionElementImpl.internal_() : super.internal_();
  get runtimeType => AnimateMotionElement;
  toString() => super.toString();
}
patch class GeometryElement {
  factory GeometryElement._internalWrap() => new GeometryElementImpl.internal_();

}
class GeometryElementImpl extends GeometryElement implements js_library.JSObjectInterfacesDom {
  GeometryElementImpl.internal_() : super.internal_();
  get runtimeType => GeometryElement;
  toString() => super.toString();
}
patch class AnimateTransformElement {
  factory AnimateTransformElement._internalWrap() => new AnimateTransformElementImpl.internal_();

}
class AnimateTransformElementImpl extends AnimateTransformElement implements js_library.JSObjectInterfacesDom {
  AnimateTransformElementImpl.internal_() : super.internal_();
  get runtimeType => AnimateTransformElement;
  toString() => super.toString();
}
patch class PreserveAspectRatio {
  factory PreserveAspectRatio._internalWrap() => new PreserveAspectRatioImpl.internal_();

}
class PreserveAspectRatioImpl extends PreserveAspectRatio implements js_library.JSObjectInterfacesDom {
  PreserveAspectRatioImpl.internal_() : super.internal_();
  get runtimeType => PreserveAspectRatio;
  toString() => super.toString();
}
patch class PathElement {
  factory PathElement._internalWrap() => new PathElementImpl.internal_();

}
class PathElementImpl extends PathElement implements js_library.JSObjectInterfacesDom {
  PathElementImpl.internal_() : super.internal_();
  get runtimeType => PathElement;
  toString() => super.toString();
}
patch class FEColorMatrixElement {
  factory FEColorMatrixElement._internalWrap() => new FEColorMatrixElementImpl.internal_();

}
class FEColorMatrixElementImpl extends FEColorMatrixElement implements js_library.JSObjectInterfacesDom {
  FEColorMatrixElementImpl.internal_() : super.internal_();
  get runtimeType => FEColorMatrixElement;
  toString() => super.toString();
}
patch class PatternElement {
  factory PatternElement._internalWrap() => new PatternElementImpl.internal_();

}
class PatternElementImpl extends PatternElement implements js_library.JSObjectInterfacesDom {
  PatternElementImpl.internal_() : super.internal_();
  get runtimeType => PatternElement;
  toString() => super.toString();
}
patch class Length {
  factory Length._internalWrap() => new LengthImpl.internal_();

}
class LengthImpl extends Length implements js_library.JSObjectInterfacesDom {
  LengthImpl.internal_() : super.internal_();
  get runtimeType => Length;
  toString() => super.toString();
}
patch class FESpotLightElement {
  factory FESpotLightElement._internalWrap() => new FESpotLightElementImpl.internal_();

}
class FESpotLightElementImpl extends FESpotLightElement implements js_library.JSObjectInterfacesDom {
  FESpotLightElementImpl.internal_() : super.internal_();
  get runtimeType => FESpotLightElement;
  toString() => super.toString();
}
patch class LineElement {
  factory LineElement._internalWrap() => new LineElementImpl.internal_();

}
class LineElementImpl extends LineElement implements js_library.JSObjectInterfacesDom {
  LineElementImpl.internal_() : super.internal_();
  get runtimeType => LineElement;
  toString() => super.toString();
}
patch class Matrix {
  factory Matrix._internalWrap() => new MatrixImpl.internal_();

}
class MatrixImpl extends Matrix implements js_library.JSObjectInterfacesDom {
  MatrixImpl.internal_() : super.internal_();
  get runtimeType => Matrix;
  toString() => super.toString();
}
patch class SvgSvgElement {
  factory SvgSvgElement._internalWrap() => new SvgSvgElementImpl.internal_();

}
class SvgSvgElementImpl extends SvgSvgElement implements js_library.JSObjectInterfacesDom {
  SvgSvgElementImpl.internal_() : super.internal_();
  get runtimeType => SvgSvgElement;
  toString() => super.toString();
}
patch class FitToViewBox {
  factory FitToViewBox._internalWrap() => new FitToViewBoxImpl.internal_();

}
class FitToViewBoxImpl extends FitToViewBox implements js_library.JSObjectInterfacesDom {
  FitToViewBoxImpl.internal_() : super.internal_();
  get runtimeType => FitToViewBox;
  toString() => super.toString();
}
patch class _SVGMPathElement {
  factory _SVGMPathElement._internalWrap() => new _SVGMPathElementImpl.internal_();

}
class _SVGMPathElementImpl extends _SVGMPathElement implements js_library.JSObjectInterfacesDom {
  _SVGMPathElementImpl.internal_() : super.internal_();
  get runtimeType => _SVGMPathElement;
  toString() => super.toString();
}
patch class FEDisplacementMapElement {
  factory FEDisplacementMapElement._internalWrap() => new FEDisplacementMapElementImpl.internal_();

}
class FEDisplacementMapElementImpl extends FEDisplacementMapElement implements js_library.JSObjectInterfacesDom {
  FEDisplacementMapElementImpl.internal_() : super.internal_();
  get runtimeType => FEDisplacementMapElement;
  toString() => super.toString();
}
patch class PathSegCurvetoQuadraticSmoothAbs {
  factory PathSegCurvetoQuadraticSmoothAbs._internalWrap() => new PathSegCurvetoQuadraticSmoothAbsImpl.internal_();

}
class PathSegCurvetoQuadraticSmoothAbsImpl extends PathSegCurvetoQuadraticSmoothAbs implements js_library.JSObjectInterfacesDom {
  PathSegCurvetoQuadraticSmoothAbsImpl.internal_() : super.internal_();
  get runtimeType => PathSegCurvetoQuadraticSmoothAbs;
  toString() => super.toString();
}
patch class PathSegClosePath {
  factory PathSegClosePath._internalWrap() => new PathSegClosePathImpl.internal_();

}
class PathSegClosePathImpl extends PathSegClosePath implements js_library.JSObjectInterfacesDom {
  PathSegClosePathImpl.internal_() : super.internal_();
  get runtimeType => PathSegClosePath;
  toString() => super.toString();
}
patch class AnimatedLength {
  factory AnimatedLength._internalWrap() => new AnimatedLengthImpl.internal_();

}
class AnimatedLengthImpl extends AnimatedLength implements js_library.JSObjectInterfacesDom {
  AnimatedLengthImpl.internal_() : super.internal_();
  get runtimeType => AnimatedLength;
  toString() => super.toString();
}
patch class ClipPathElement {
  factory ClipPathElement._internalWrap() => new ClipPathElementImpl.internal_();

}
class ClipPathElementImpl extends ClipPathElement implements js_library.JSObjectInterfacesDom {
  ClipPathElementImpl.internal_() : super.internal_();
  get runtimeType => ClipPathElement;
  toString() => super.toString();
}
patch class StopElement {
  factory StopElement._internalWrap() => new StopElementImpl.internal_();

}
class StopElementImpl extends StopElement implements js_library.JSObjectInterfacesDom {
  StopElementImpl.internal_() : super.internal_();
  get runtimeType => StopElement;
  toString() => super.toString();
}
patch class ViewSpec {
  factory ViewSpec._internalWrap() => new ViewSpecImpl.internal_();

}
class ViewSpecImpl extends ViewSpec implements js_library.JSObjectInterfacesDom {
  ViewSpecImpl.internal_() : super.internal_();
  get runtimeType => ViewSpec;
  toString() => super.toString();
}
patch class LengthList {
  factory LengthList._internalWrap() => new LengthListImpl.internal_();

}
class LengthListImpl extends LengthList implements js_library.JSObjectInterfacesDom {
  LengthListImpl.internal_() : super.internal_();
  get runtimeType => LengthList;
  toString() => super.toString();
}
patch class _SVGCursorElement {
  factory _SVGCursorElement._internalWrap() => new _SVGCursorElementImpl.internal_();

}
class _SVGCursorElementImpl extends _SVGCursorElement implements js_library.JSObjectInterfacesDom {
  _SVGCursorElementImpl.internal_() : super.internal_();
  get runtimeType => _SVGCursorElement;
  toString() => super.toString();
}
patch class ForeignObjectElement {
  factory ForeignObjectElement._internalWrap() => new ForeignObjectElementImpl.internal_();

}
class ForeignObjectElementImpl extends ForeignObjectElement implements js_library.JSObjectInterfacesDom {
  ForeignObjectElementImpl.internal_() : super.internal_();
  get runtimeType => ForeignObjectElement;
  toString() => super.toString();
}
patch class SetElement {
  factory SetElement._internalWrap() => new SetElementImpl.internal_();

}
class SetElementImpl extends SetElement implements js_library.JSObjectInterfacesDom {
  SetElementImpl.internal_() : super.internal_();
  get runtimeType => SetElement;
  toString() => super.toString();
}
patch class SvgElement {
  factory SvgElement._internalWrap() => new SvgElementImpl.internal_();

}
class SvgElementImpl extends SvgElement implements js_library.JSObjectInterfacesDom {
  SvgElementImpl.internal_() : super.internal_();
  get runtimeType => SvgElement;
  toString() => super.toString();
}
patch class UnitTypes {
  factory UnitTypes._internalWrap() => new UnitTypesImpl.internal_();

}
class UnitTypesImpl extends UnitTypes implements js_library.JSObjectInterfacesDom {
  UnitTypesImpl.internal_() : super.internal_();
  get runtimeType => UnitTypes;
  toString() => super.toString();
}
patch class FEComponentTransferElement {
  factory FEComponentTransferElement._internalWrap() => new FEComponentTransferElementImpl.internal_();

}
class FEComponentTransferElementImpl extends FEComponentTransferElement implements js_library.JSObjectInterfacesDom {
  FEComponentTransferElementImpl.internal_() : super.internal_();
  get runtimeType => FEComponentTransferElement;
  toString() => super.toString();
}
patch class DescElement {
  factory DescElement._internalWrap() => new DescElementImpl.internal_();

}
class DescElementImpl extends DescElement implements js_library.JSObjectInterfacesDom {
  DescElementImpl.internal_() : super.internal_();
  get runtimeType => DescElement;
  toString() => super.toString();
}
patch class DiscardElement {
  factory DiscardElement._internalWrap() => new DiscardElementImpl.internal_();

}
class DiscardElementImpl extends DiscardElement implements js_library.JSObjectInterfacesDom {
  DiscardElementImpl.internal_() : super.internal_();
  get runtimeType => DiscardElement;
  toString() => super.toString();
}
patch class PathSegLinetoVerticalAbs {
  factory PathSegLinetoVerticalAbs._internalWrap() => new PathSegLinetoVerticalAbsImpl.internal_();

}
class PathSegLinetoVerticalAbsImpl extends PathSegLinetoVerticalAbs implements js_library.JSObjectInterfacesDom {
  PathSegLinetoVerticalAbsImpl.internal_() : super.internal_();
  get runtimeType => PathSegLinetoVerticalAbs;
  toString() => super.toString();
}
patch class FEMergeNodeElement {
  factory FEMergeNodeElement._internalWrap() => new FEMergeNodeElementImpl.internal_();

}
class FEMergeNodeElementImpl extends FEMergeNodeElement implements js_library.JSObjectInterfacesDom {
  FEMergeNodeElementImpl.internal_() : super.internal_();
  get runtimeType => FEMergeNodeElement;
  toString() => super.toString();
}
patch class TextPathElement {
  factory TextPathElement._internalWrap() => new TextPathElementImpl.internal_();

}
class TextPathElementImpl extends TextPathElement implements js_library.JSObjectInterfacesDom {
  TextPathElementImpl.internal_() : super.internal_();
  get runtimeType => TextPathElement;
  toString() => super.toString();
}
patch class FEOffsetElement {
  factory FEOffsetElement._internalWrap() => new FEOffsetElementImpl.internal_();

}
class FEOffsetElementImpl extends FEOffsetElement implements js_library.JSObjectInterfacesDom {
  FEOffsetElementImpl.internal_() : super.internal_();
  get runtimeType => FEOffsetElement;
  toString() => super.toString();
}
patch class ZoomAndPan {
  factory ZoomAndPan._internalWrap() => new ZoomAndPanImpl.internal_();

}
class ZoomAndPanImpl extends ZoomAndPan implements js_library.JSObjectInterfacesDom {
  ZoomAndPanImpl.internal_() : super.internal_();
  get runtimeType => ZoomAndPan;
  toString() => super.toString();
}
patch class ViewElement {
  factory ViewElement._internalWrap() => new ViewElementImpl.internal_();

}
class ViewElementImpl extends ViewElement implements js_library.JSObjectInterfacesDom {
  ViewElementImpl.internal_() : super.internal_();
  get runtimeType => ViewElement;
  toString() => super.toString();
}
patch class FEPointLightElement {
  factory FEPointLightElement._internalWrap() => new FEPointLightElementImpl.internal_();

}
class FEPointLightElementImpl extends FEPointLightElement implements js_library.JSObjectInterfacesDom {
  FEPointLightElementImpl.internal_() : super.internal_();
  get runtimeType => FEPointLightElement;
  toString() => super.toString();
}
patch class FEFuncAElement {
  factory FEFuncAElement._internalWrap() => new FEFuncAElementImpl.internal_();

}
class FEFuncAElementImpl extends FEFuncAElement implements js_library.JSObjectInterfacesDom {
  FEFuncAElementImpl.internal_() : super.internal_();
  get runtimeType => FEFuncAElement;
  toString() => super.toString();
}

"""],"dart:web_audio": ["dart:web_audio", "dart:web_audio_js_interop_patch.dart", """import 'dart:js' as js_library;

/**
 * Placeholder object for cases where we need to determine exactly how many
 * args were passed to a function.
 */
const _UNDEFINED_JS_CONST = const Object();

patch class GainNode {
  factory GainNode._internalWrap() => new GainNodeImpl.internal_();

}
class GainNodeImpl extends GainNode implements js_library.JSObjectInterfacesDom {
  GainNodeImpl.internal_() : super.internal_();
  get runtimeType => GainNode;
  toString() => super.toString();
}
patch class MediaStreamAudioDestinationNode {
  factory MediaStreamAudioDestinationNode._internalWrap() => new MediaStreamAudioDestinationNodeImpl.internal_();

}
class MediaStreamAudioDestinationNodeImpl extends MediaStreamAudioDestinationNode implements js_library.JSObjectInterfacesDom {
  MediaStreamAudioDestinationNodeImpl.internal_() : super.internal_();
  get runtimeType => MediaStreamAudioDestinationNode;
  toString() => super.toString();
}
patch class AudioProcessingEvent {
  factory AudioProcessingEvent._internalWrap() => new AudioProcessingEventImpl.internal_();

}
class AudioProcessingEventImpl extends AudioProcessingEvent implements js_library.JSObjectInterfacesDom {
  AudioProcessingEventImpl.internal_() : super.internal_();
  get runtimeType => AudioProcessingEvent;
  toString() => super.toString();
}
patch class StereoPannerNode {
  factory StereoPannerNode._internalWrap() => new StereoPannerNodeImpl.internal_();

}
class StereoPannerNodeImpl extends StereoPannerNode implements js_library.JSObjectInterfacesDom {
  StereoPannerNodeImpl.internal_() : super.internal_();
  get runtimeType => StereoPannerNode;
  toString() => super.toString();
}
patch class DynamicsCompressorNode {
  factory DynamicsCompressorNode._internalWrap() => new DynamicsCompressorNodeImpl.internal_();

}
class DynamicsCompressorNodeImpl extends DynamicsCompressorNode implements js_library.JSObjectInterfacesDom {
  DynamicsCompressorNodeImpl.internal_() : super.internal_();
  get runtimeType => DynamicsCompressorNode;
  toString() => super.toString();
}
patch class PeriodicWave {
  factory PeriodicWave._internalWrap() => new PeriodicWaveImpl.internal_();

}
class PeriodicWaveImpl extends PeriodicWave implements js_library.JSObjectInterfacesDom {
  PeriodicWaveImpl.internal_() : super.internal_();
  get runtimeType => PeriodicWave;
  toString() => super.toString();
}
patch class MediaStreamAudioSourceNode {
  factory MediaStreamAudioSourceNode._internalWrap() => new MediaStreamAudioSourceNodeImpl.internal_();

}
class MediaStreamAudioSourceNodeImpl extends MediaStreamAudioSourceNode implements js_library.JSObjectInterfacesDom {
  MediaStreamAudioSourceNodeImpl.internal_() : super.internal_();
  get runtimeType => MediaStreamAudioSourceNode;
  toString() => super.toString();
}
patch class PannerNode {
  factory PannerNode._internalWrap() => new PannerNodeImpl.internal_();

}
class PannerNodeImpl extends PannerNode implements js_library.JSObjectInterfacesDom {
  PannerNodeImpl.internal_() : super.internal_();
  get runtimeType => PannerNode;
  toString() => super.toString();
}
patch class OfflineAudioContext {
  factory OfflineAudioContext._internalWrap() => new OfflineAudioContextImpl.internal_();

}
class OfflineAudioContextImpl extends OfflineAudioContext implements js_library.JSObjectInterfacesDom {
  OfflineAudioContextImpl.internal_() : super.internal_();
  get runtimeType => OfflineAudioContext;
  toString() => super.toString();
}
patch class AudioParam {
  factory AudioParam._internalWrap() => new AudioParamImpl.internal_();

}
class AudioParamImpl extends AudioParam implements js_library.JSObjectInterfacesDom {
  AudioParamImpl.internal_() : super.internal_();
  get runtimeType => AudioParam;
  toString() => super.toString();
}
patch class AnalyserNode {
  factory AnalyserNode._internalWrap() => new AnalyserNodeImpl.internal_();

}
class AnalyserNodeImpl extends AnalyserNode implements js_library.JSObjectInterfacesDom {
  AnalyserNodeImpl.internal_() : super.internal_();
  get runtimeType => AnalyserNode;
  toString() => super.toString();
}
patch class ConvolverNode {
  factory ConvolverNode._internalWrap() => new ConvolverNodeImpl.internal_();

}
class ConvolverNodeImpl extends ConvolverNode implements js_library.JSObjectInterfacesDom {
  ConvolverNodeImpl.internal_() : super.internal_();
  get runtimeType => ConvolverNode;
  toString() => super.toString();
}
patch class AudioNode {
  factory AudioNode._internalWrap() => new AudioNodeImpl.internal_();

}
class AudioNodeImpl extends AudioNode implements js_library.JSObjectInterfacesDom {
  AudioNodeImpl.internal_() : super.internal_();
  get runtimeType => AudioNode;
  toString() => super.toString();
}
patch class AudioDestinationNode {
  factory AudioDestinationNode._internalWrap() => new AudioDestinationNodeImpl.internal_();

}
class AudioDestinationNodeImpl extends AudioDestinationNode implements js_library.JSObjectInterfacesDom {
  AudioDestinationNodeImpl.internal_() : super.internal_();
  get runtimeType => AudioDestinationNode;
  toString() => super.toString();
}
patch class WaveShaperNode {
  factory WaveShaperNode._internalWrap() => new WaveShaperNodeImpl.internal_();

}
class WaveShaperNodeImpl extends WaveShaperNode implements js_library.JSObjectInterfacesDom {
  WaveShaperNodeImpl.internal_() : super.internal_();
  get runtimeType => WaveShaperNode;
  toString() => super.toString();
}
patch class ScriptProcessorNode {
  factory ScriptProcessorNode._internalWrap() => new ScriptProcessorNodeImpl.internal_();

}
class ScriptProcessorNodeImpl extends ScriptProcessorNode implements js_library.JSObjectInterfacesDom {
  ScriptProcessorNodeImpl.internal_() : super.internal_();
  get runtimeType => ScriptProcessorNode;
  toString() => super.toString();
}
patch class MediaElementAudioSourceNode {
  factory MediaElementAudioSourceNode._internalWrap() => new MediaElementAudioSourceNodeImpl.internal_();

}
class MediaElementAudioSourceNodeImpl extends MediaElementAudioSourceNode implements js_library.JSObjectInterfacesDom {
  MediaElementAudioSourceNodeImpl.internal_() : super.internal_();
  get runtimeType => MediaElementAudioSourceNode;
  toString() => super.toString();
}
patch class AudioBufferSourceNode {
  factory AudioBufferSourceNode._internalWrap() => new AudioBufferSourceNodeImpl.internal_();

}
class AudioBufferSourceNodeImpl extends AudioBufferSourceNode implements js_library.JSObjectInterfacesDom {
  AudioBufferSourceNodeImpl.internal_() : super.internal_();
  get runtimeType => AudioBufferSourceNode;
  toString() => super.toString();
}
patch class AudioContext {
  factory AudioContext._internalWrap() => new AudioContextImpl.internal_();

}
class AudioContextImpl extends AudioContext implements js_library.JSObjectInterfacesDom {
  AudioContextImpl.internal_() : super.internal_();
  get runtimeType => AudioContext;
  toString() => super.toString();
}
patch class ChannelSplitterNode {
  factory ChannelSplitterNode._internalWrap() => new ChannelSplitterNodeImpl.internal_();

}
class ChannelSplitterNodeImpl extends ChannelSplitterNode implements js_library.JSObjectInterfacesDom {
  ChannelSplitterNodeImpl.internal_() : super.internal_();
  get runtimeType => ChannelSplitterNode;
  toString() => super.toString();
}
patch class DelayNode {
  factory DelayNode._internalWrap() => new DelayNodeImpl.internal_();

}
class DelayNodeImpl extends DelayNode implements js_library.JSObjectInterfacesDom {
  DelayNodeImpl.internal_() : super.internal_();
  get runtimeType => DelayNode;
  toString() => super.toString();
}
patch class OfflineAudioCompletionEvent {
  factory OfflineAudioCompletionEvent._internalWrap() => new OfflineAudioCompletionEventImpl.internal_();

}
class OfflineAudioCompletionEventImpl extends OfflineAudioCompletionEvent implements js_library.JSObjectInterfacesDom {
  OfflineAudioCompletionEventImpl.internal_() : super.internal_();
  get runtimeType => OfflineAudioCompletionEvent;
  toString() => super.toString();
}
patch class OscillatorNode {
  factory OscillatorNode._internalWrap() => new OscillatorNodeImpl.internal_();

}
class OscillatorNodeImpl extends OscillatorNode implements js_library.JSObjectInterfacesDom {
  OscillatorNodeImpl.internal_() : super.internal_();
  get runtimeType => OscillatorNode;
  toString() => super.toString();
}
patch class BiquadFilterNode {
  factory BiquadFilterNode._internalWrap() => new BiquadFilterNodeImpl.internal_();

}
class BiquadFilterNodeImpl extends BiquadFilterNode implements js_library.JSObjectInterfacesDom {
  BiquadFilterNodeImpl.internal_() : super.internal_();
  get runtimeType => BiquadFilterNode;
  toString() => super.toString();
}
patch class AudioBuffer {
  factory AudioBuffer._internalWrap() => new AudioBufferImpl.internal_();

}
class AudioBufferImpl extends AudioBuffer implements js_library.JSObjectInterfacesDom {
  AudioBufferImpl.internal_() : super.internal_();
  get runtimeType => AudioBuffer;
  toString() => super.toString();
}
patch class AudioListener {
  factory AudioListener._internalWrap() => new AudioListenerImpl.internal_();

}
class AudioListenerImpl extends AudioListener implements js_library.JSObjectInterfacesDom {
  AudioListenerImpl.internal_() : super.internal_();
  get runtimeType => AudioListener;
  toString() => super.toString();
}
patch class ChannelMergerNode {
  factory ChannelMergerNode._internalWrap() => new ChannelMergerNodeImpl.internal_();

}
class ChannelMergerNodeImpl extends ChannelMergerNode implements js_library.JSObjectInterfacesDom {
  ChannelMergerNodeImpl.internal_() : super.internal_();
  get runtimeType => ChannelMergerNode;
  toString() => super.toString();
}
patch class AudioSourceNode {
  factory AudioSourceNode._internalWrap() => new AudioSourceNodeImpl.internal_();

}
class AudioSourceNodeImpl extends AudioSourceNode implements js_library.JSObjectInterfacesDom {
  AudioSourceNodeImpl.internal_() : super.internal_();
  get runtimeType => AudioSourceNode;
  toString() => super.toString();
}

"""],};
// END_OF_CACHED_PATCHES
