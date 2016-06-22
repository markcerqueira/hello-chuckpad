# chuckpad-social-ios

Sample iOS client that interacts with the [chuckpad-social][1] service.

Notes:
* Requires AFNetworking and FXKeychain
* ChuckPad Social SDK is all in *chuckpad-social*
* Link with Security.framework in Build Phases (ChuckPadSocial uses [FXKeychain][2] internally to store some sensitive information)

[1]: https://github.com/markcerqueira/chuckpad-social
[2]: https://github.com/nicklockwood/FXKeychain
