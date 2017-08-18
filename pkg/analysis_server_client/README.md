# Analysis Server Client

A client wrapper over Analysis Server. Instances of this client manages
connection to Analysis Server and process and faciliates JSON protocol
communication to and from the server. 

Current implementation has no knowledge of the Analysis Server library yet.
Future updates will allow for full class-access of Analysis Server protocol
objects. 

Analysis Server process must be instantiated separately and loaded into
Analysis Server Client. To learn how to generate an Analysis Server Process,
refer to the [Analysis Server page.](https://github.com/dart-lang/sdk/tree/master/pkg/analysis_server)
