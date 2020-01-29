# Note to Self
An app to email yourself notes

https://notetoselfapp.com/

Note to Self is a simple app for you to email yourself that note you need to remember! Verify your email and you're good to go! Just open the app, type out your note, and swipe left or right to send the email.

The purpose for Note to Self is to be very quick and simple to use. Forget needing to login to any email servers. Just validate your email and send!

## Start contributing

You can start by forking this repository and creating pull requests on the master branch.

### Additional Setup
Additional setup is required for this project to work compile. While all of the pods are intentionally included in the repo, there is a `SecureMail.swift` file that is included in the `.gitignore` which contains the API and API Key for Note to Self. To ensure that this project runs, please create a `SecureMail.swift` file with the following variables and function as shown in the example below
```swift
class SecureMail {
    static let apiKey = "<API KEY>"
    static let email = "<DESIRED EMAIL ADDRESS TO SEND FROM>"
    static let url = "<URL TO THE API>"

    // This function is used to ensure that the text is valid to send
    // through the API. You can create an empty function, or remove
    // SecureMail.validate() call from Emails.sendEmail function
    static func validate(_ text: String) { ... }
}
```
The API should accept a POST request with the following parameters, and authenticating with the user "api" and the API Key as the password.
```
{
  "from": <DESIRED EMAIL ADDRESS TO SEND FROM>,
  "to": <DESIRED EMAIL TO SEND TO>,
  "subject": <SUBJECT OF THE EMAIL>,
  "text": <BODY OF THE EMAIL>
}
```
If the email is sent, the request will respond with a 200 code. Any other status code will be assumed as an error.

Additional signing of the project and setting up of the recurring In-App Purchase would be required by the developer to ensure that purchasing Pro through the Apple API is available. By default, when debugging Pro is enabled. To test as a user that has not yet purchased Pro, run the application's build configuration as Release (this can be done by profiling the application if the scheme is default, or editing the scheme to run it as Release).

## Support
If you need assistance or want to ask a question about the iOS app, you are welcome to reach out and [email](mailto:support@notetoselfapp.com). If you have found a bug, feel free to [open a new Issue on GitHub](https://github.com/blakedgordon/Note-to-Self-iOS/issues).

## License

Note to Self is open source under the GNU AGPLv3 license. See [LICENSE](LICENSE.txt) for more information.
