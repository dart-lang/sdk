
class InspectorFrontendHost native "*InspectorFrontendHost" {

  void bringToFront() native;

  void closeWindow() native;

  void copyText(String text) native;

  void disconnectFromBackend() native;

  String hiddenPanels() native;

  void inspectedURLChanged(String newURL) native;

  void loaded() native;

  String localizedStringsURL() native;

  void moveWindowBy(num x, num y) native;

  String platform() native;

  String port() native;

  void recordActionTaken(int actionCode) native;

  void recordPanelShown(int panelCode) native;

  void recordSettingChanged(int settingChanged) native;

  void requestAttachWindow() native;

  void requestDetachWindow() native;

  void saveAs(String fileName, String content) native;

  void sendMessageToBackend(String message) native;

  void setAttachedWindowHeight(int height) native;

  void setExtensionAPI(String script) native;

  void showContextMenu(MouseEvent event, Object items) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
