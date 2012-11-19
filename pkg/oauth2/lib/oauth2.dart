// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A client library for authenticating with a remote service via OAuth2 on
/// behalf of a user, and making authorized HTTP requests with the user's OAuth2
/// credentials.
///
/// OAuth2 allows a client (the program using this library) to access and
/// manipulate a resource that's owned by a resource owner (the end user) and
/// lives on a remote server. The client directs the resource owner to an
/// authorization server (usually but not always the same as the server that
/// hosts the resource), where the resource owner tells the authorization server
/// to give the client an access token. This token serves as proof that the
/// client has permission to access resources on behalf of the resource owner.
///
/// OAuth2 provides several different methods for the client to obtain
/// authorization. At the time of writing, this library only supports the
/// [AuthorizationCodeGrant] method, but further methods may be added in the
/// future. The following example uses this method to authenticate, and assumes
/// that the library is being used by a server-side application.
///
///     import 'dart:io'
///     import 'dart:uri'
///     import 'package:oauth2/oauth2.dart' as oauth2;
///
///     // These URLs are endpoints that are provided by the authorization
///     // server. They're usually included in the server's documentation of its
///     // OAuth2 API.
///     final authorizationEndpoint =
///         new Uri.fromString("http://example.com/oauth2/authorization");
///     final tokenEndpoint =
///         new Uri.fromString("http://example.com/oauth2/token");
///     
///     // The authorization server will issue each client a separate client
///     // identifier and secret, which allows the server to tell which client
///     // is accessing it. Some servers may also have an anonymous
///     // identifier/secret pair that any client may use.
///     //
///     // Note that clients whose source code or binary executable is readily
///     // available may not be able to make sure the client secret is kept a
///     // secret. This is fine; OAuth2 servers generally won't rely on knowing
///     // with certainty that a client is who it claims to be.
///     final identifier = "my client identifier";
///     final secret = "my client secret";
///
///     // This is a URL on your application's server. The authorization server
///     // will redirect the resource owner here once they've authorized the
///     // client. The redirection will include the authorization code in the
///     // query parameters.
///     final redirectUrl = new Uri.fromString(
///         "http://my-site.com/oauth2-redirect");
///     
///     var credentialsFile = new File("~/.myapp/credentials.json");
///     return credentialsFile.exists().chain((exists) {
///       // If the OAuth2 credentials have already been saved from a previous
///       // run, we just want to reload them.
///       if (exists) {
///         return credentialsFile.readAsText().transform((json) {
///           var credentials = new oauth2.Credentials.fromJson(json);
///           return new oauth2.Client(identifier, secret, credentials);
///         });
///       }
///     
///       // If we don't have OAuth2 credentials yet, we need to get the
///       // resource owner to authorize us. We're assuming here that we're a
///       // command-line application.
///       var grant = new oauth2.AuthorizationCodeGrant(
///           identifier, secret, authorizationEndpoint, tokenEndpoint);
///     
///       // Redirect the resource owner to the authorization URL. This will be
///       // a URL on the authorization server (authorizationEndpoint with some
///       // additional query parameters). Once the resource owner has
///       // authorized, they'll be redirected to `redirectUrl` with an
///       // authorization code.
///       //
///       // `redirect` is an imaginary function that redirects the resource
///       // owner's browser.
///       return redirect(grant.getAuthorizationUrl(redirectUrl)).chain((_) {
///         // Another imaginary function that listens for a request to
///         // `redirectUrl`.
///         return listen(redirectUrl);
///       }).transform((request) {
///         // Once the user is redirected to `redirectUrl`, pass the query
///         // parameters to the AuthorizationCodeGrant. It will validate them
///         // and extract the authorization code to create a new Client.
///         return grant.handleAuthorizationResponse(request.queryParameters);
///       })
///     }).chain((client) {
///       // Once you have a Client, you can use it just like any other HTTP
///       // client.
///       return client.read("http://example.com/protected-resources.txt")
///           .transform((result) {
///         // Once we're done with the client, save the credentials file. This
///         // ensures that if the credentials were automatically refreshed
///         // while using the client, the new credentials are available for the
///         // next run of the program.
///         return credentialsFile.open(FileMode.WRITE).chain((file) {
///           return file.writeString(client.credentials.toJson());
///         }).chain((file) => file.close()).transform((_) => result);
///       });
///     }).then(print);
library oauth2;

export 'src/authorization_code_grant.dart';
export 'src/client.dart';
export 'src/credentials.dart';
export 'src/authorization_exception.dart';
export 'src/expiration_exception.dart';
