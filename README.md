# hello-chuckpad

Sample iOS client that interacts with the [chuckpad-social][1] service. 
The iOS library code that interacts with the chuckpad-social server is stored as a git submodule (see [chuckpad-social-ios][2]).

The primary usage of this repository is to host a [suite of unit tests][4], which run alonside a local instance of chuckpad-social, thoroughly exercises both iOS and server code.

If you are getting keychain write issues (`FXKeychain failed to store data for key, error: -34018`) try setting up [Keychain Access Groups][3].

[1]: https://github.com/markcerqueira/chuckpad-social
[2]: https://github.com/markcerqueira/chuckpad-social-ios
[3]: http://stackoverflow.com/a/38543243
[4]: https://github.com/markcerqueira/hello-chuckpad/tree/master/unit-tests
