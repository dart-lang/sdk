// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface InspectorFrontendHost {

  void bringToFront();

  void closeWindow();

  void copyText(String text);

  void disconnectFromBackend();

  String hiddenPanels();

  void inspectedURLChanged(String newURL);

  void loaded();

  String localizedStringsURL();

  void moveWindowBy(num x, num y);

  String platform();

  String port();

  void recordActionTaken(int actionCode);

  void recordPanelShown(int panelCode);

  void recordSettingChanged(int settingChanged);

  void requestAttachWindow();

  void requestDetachWindow();

  void saveAs(String fileName, String content);

  void sendMessageToBackend(String message);

  void setAttachedWindowHeight(int height);

  void setExtensionAPI(String script);

  void showContextMenu(MouseEvent event, Object items);
}
