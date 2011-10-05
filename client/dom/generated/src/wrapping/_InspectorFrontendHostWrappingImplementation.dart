// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _InspectorFrontendHostWrappingImplementation extends DOMWrapperBase implements InspectorFrontendHost {
  _InspectorFrontendHostWrappingImplementation() : super() {}

  static create__InspectorFrontendHostWrappingImplementation() native {
    return new _InspectorFrontendHostWrappingImplementation();
  }

  void bringToFront() {
    _bringToFront(this);
    return;
  }
  static void _bringToFront(receiver) native;

  void closeWindow() {
    _closeWindow(this);
    return;
  }
  static void _closeWindow(receiver) native;

  void copyText(String text) {
    _copyText(this, text);
    return;
  }
  static void _copyText(receiver, text) native;

  void disconnectFromBackend() {
    _disconnectFromBackend(this);
    return;
  }
  static void _disconnectFromBackend(receiver) native;

  String hiddenPanels() {
    return _hiddenPanels(this);
  }
  static String _hiddenPanels(receiver) native;

  void inspectedURLChanged(String newURL) {
    _inspectedURLChanged(this, newURL);
    return;
  }
  static void _inspectedURLChanged(receiver, newURL) native;

  void loaded() {
    _loaded(this);
    return;
  }
  static void _loaded(receiver) native;

  String localizedStringsURL() {
    return _localizedStringsURL(this);
  }
  static String _localizedStringsURL(receiver) native;

  void moveWindowBy(num x, num y) {
    _moveWindowBy(this, x, y);
    return;
  }
  static void _moveWindowBy(receiver, x, y) native;

  String platform() {
    return _platform(this);
  }
  static String _platform(receiver) native;

  String port() {
    return _port(this);
  }
  static String _port(receiver) native;

  void recordActionTaken(int actionCode) {
    _recordActionTaken(this, actionCode);
    return;
  }
  static void _recordActionTaken(receiver, actionCode) native;

  void recordPanelShown(int panelCode) {
    _recordPanelShown(this, panelCode);
    return;
  }
  static void _recordPanelShown(receiver, panelCode) native;

  void recordSettingChanged(int settingChanged) {
    _recordSettingChanged(this, settingChanged);
    return;
  }
  static void _recordSettingChanged(receiver, settingChanged) native;

  void requestAttachWindow() {
    _requestAttachWindow(this);
    return;
  }
  static void _requestAttachWindow(receiver) native;

  void requestDetachWindow() {
    _requestDetachWindow(this);
    return;
  }
  static void _requestDetachWindow(receiver) native;

  void saveAs(String fileName, String content) {
    _saveAs(this, fileName, content);
    return;
  }
  static void _saveAs(receiver, fileName, content) native;

  void sendMessageToBackend(String message) {
    _sendMessageToBackend(this, message);
    return;
  }
  static void _sendMessageToBackend(receiver, message) native;

  void setAttachedWindowHeight(int height) {
    _setAttachedWindowHeight(this, height);
    return;
  }
  static void _setAttachedWindowHeight(receiver, height) native;

  void setExtensionAPI(String script) {
    _setExtensionAPI(this, script);
    return;
  }
  static void _setExtensionAPI(receiver, script) native;

  void showContextMenu(MouseEvent event, Object items) {
    _showContextMenu(this, event, items);
    return;
  }
  static void _showContextMenu(receiver, event, items) native;

  String get typeName() { return "InspectorFrontendHost"; }
}
