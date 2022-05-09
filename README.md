# Agora Marketplace

## System requirements

To install and run AgoraMarketplace, your development environment must meet these minimum
requirements:

### macOS

- **Operating Systems**: macOS
- **Disk Space**: 1 GB (does not include disk space for IDE/tools).
- **Tools**:
    - AgoraMarketplace uses `git` for installation and upgrade. We recommend
      installing [Xcode](https://developer.apple.com/xcode/), which includes `git`, but you can also
      [install `git` separately](https://git-scm.com/download/mac).
    - AgoraMarketplace uses `CMake` for compile. [install `CMake`](https://cmake.org/download/).

### Windows

## Get the AgoraMarketplace {#get-sdk}

1. Download the following installation bundle to get the latest {{site.sdk.channel}} release of the
   AgoraMarketplace SDK:

   [(loading...)](#){:.download-latest-link-{{os}}.btn.btn-primary}

   For other release channels, and older builds, see the [SDK releases][] page.

1. Extract the file in the desired location, for example:

   {% comment %} Our JS also updates the filename in this template, but it doesn't include the
   terminal formatting:

   {% prettify shell %} $ cd ~/development $ unzip ~/Downloads/[[download-latest-link-filename]]
   flutter_{{os}}_vX.X.X-{{site.sdk.channel}}.zip[[/end]]
   {% endprettify %} {% endcomment -%}

   ```terminal
   $ cd ~/development
   $ unzip ~/Downloads/flutter_{{os}}_vX.X.X-{{site.sdk.channel}}.zip
   ```

1. Add the `AgoraMarketplace` tool to your path:

   ```terminal
   $ export AGORA_MARKETPLACE_ROOT="`pwd`/[PATH_OF_AGORA_MARKETPLACE_GIT_DIRECTORY]"
   $ export PATH="$PATH:$AGORA_MARKETPLACE_ROOT/bin"
   ```

   This command sets your `PATH` variable for the
   _current_ terminal window only. To permanently add AgoraMarketplace to your path, see
   [Update your path][].

You are now ready to run AgoraMarketplace commands!

{{site.alert.note}} To update an existing version of AgoraMarketplace, see
[Upgrading AgoraMarketplace][]. {{site.alert.end}}

### Update your path

You can update your PATH variable for the current session at the command line, as shown
in [Get the AgoraMarketplace SDK][]. You'll probably want to update this variable permanently, so
you can run `amtool` commands in any terminal session.

The steps for modifying this variable permanently for all terminal sessions are machine-specific.
Typically you add a line to a file that is executed whenever you open a new window. For example:

1. Determine the path of your clone of the AgoraMarketplace SDK. You need this in Step 3.
2. Open (or create) the `rc` file for your shell. Typing `echo $SHELL` in your Terminal tells you
   which shell you're using. If you're using Bash, edit `$HOME/.bash_profile` or `$HOME/.bashrc`. If
   you're using Z shell, edit `$HOME/.zshrc`. If you're using a different shell, the file path and
   filename will be different on your machine.
3. Add the following line and change
   `[PATH_OF_AGORA_MARKETPLACE_GIT_DIRECTORY]` to be the path of your clone of the AgoraMarketplace
   git repo:

   ```terminal
   $ export AGORA_MARKETPLACE_ROOT="$HOME/[PATH_OF_AGORA_MARKETPLACE_GIT_DIRECTORY]"
   $ export PATH="$PATH:$AGORA_MARKETPLACE_ROOT/bin"
   ```

4. Run `source $HOME/.<rc file>`
   to refresh the current window, or open a new terminal window to automatically source the file.
5. Verify that the `AgoraMarketplace/bin` directory is now in your PATH by running:

   ```terminal
   $ echo $PATH
   ```
   Verify that the `amtool` command is available by running:

   ```terminal
   $ which amtool
   ```

## Platform setup

macOS supports developing AgoraMarketplace extensions in iOS, Android. Complete at least one of the
platform setup steps now, to be able to build and run your first AgoraMarketplace extension.

## Android setup

{{site.alert.note}} AgoraMarketplace relies on a full installation of Android Studio to supply its
Android platform dependencies. However, you can write your AgoraMarketplace extensions in a number
of editors; a later step discusses that. {{site.alert.end}}

### Install Android Studio

1. Download and install [Android Studio](https://developer.android.com/studio).
1. Start Android Studio, and go through the 'Android Studio Setup Wizard'. This installs the latest
   Android SDK, Android SDK Command-line Tools, and Android SDK Build-Tools, which are required by
   AgoraMarketplace when developing for Android.

### Set up your Android device

To prepare to run and test your AgoraMarketplace extension on an Android device, you need an Android
device running Android 4.1 (API level 16) or higher.

1. Enable **Developer options** and **USB debugging** on your device. Detailed instructions are
   available in the
   [Android documentation](https://developer.android.com/studio/debug/dev-options).
1. Windows-only: Install the [Google USB Driver](https://developer.android.com/studio/run/win-usb).
1. Using a USB cable, plug your phone into your computer. If prompted on your device, authorize your
   computer to access your device.

### Create and run a simple AgoraMarketplace extension

To create your first AgoraMarketplace extension and test your setup, follow these steps:

1. Create a new AgoraMarketplace extension by running the following from the command line:

   ```terminal
   $ amtool create my_extension
   ```

2. A `my_extension` directory is created, containing AgoraMarketplace's demo app. Enter this
   directory:

   ```terminal
   $ cd my_extension
   ```

3. To compile the extension in the Simulator, enter:

   ```terminal
   $ amtool build -t aar
   ```

## iOS setup

### Install Xcode

To develop AgoraMarketplace extensions for iOS, you need a Mac with Xcode installed.

1. Install the latest stable version of Xcode
   (using [web download](https://developer.apple.com/xcode/) or
   the [Mac App Store](https://itunes.apple.com/us/app/xcode/id497799835)).
1. Configure the Xcode command-line tools to use the newly-installed version of Xcode by running the
   following from the command line:

   ```terminal
   $ sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   $ sudo xcodebuild -runFirstLaunch
   ```

   This is the correct path for most cases, when you want to use the latest version of Xcode. If you
   need to use a different version, specify that path instead.

1. Make sure the Xcode license agreement is signed by either opening Xcode once and confirming or
   running
   `sudo xcodebuild -license` from the command line.

Versions older than the latest stable version may still work, but are not recommended for
AgoraMarketplace development. Using old versions of Xcode to target bitcode is not supported, and is
likely not to work.

With Xcode, you’ll be able to run AgoraMarketplace extensions on an iOS device or on the simulator.

### Create and run a simple AgoraMarketplace extension

To create your first AgoraMarketplace extension and test your setup, follow these steps:

1. Create a new AgoraMarketplace extension by running the following from the command line:

   ```terminal
   $ amtool create my_extension
   ```

2. A `my_extension` directory is created, containing AgoraMarketplace's demo app. Enter this
   directory:

   ```terminal
   $ cd my_extension
   ```

3. To compile the extension in the Simulator, enter:

   ```terminal
   $ amtool build -t framework
   ```

### Deploy to iOS devices

To deploy your AgoraMarketplace app to a physical iOS device you'll need to set up physical device
deployment in Xcode and an Apple Developer account. If your app is using AgoraMarketplace plugins,
you will also need the third-party CocoaPods dependency manager.

<ol markdown="1">
<li markdown="1">

[Install and set up CocoaPods](https://guides.cocoapods.org/using/getting-started.html#installation)
by running the following commands:

```terminal
$ sudo gem install cocoapods
```

{{site.alert.note}} The default version of Ruby requires `sudo` to install the CocoaPods gem. If you
are using a Ruby Version manager, you may need to run without `sudo`. {{site.alert.end}}

</li>

<li markdown="1">

Follow the Xcode signing flow to provision your project:

{: type="a"}

1. Open the default Xcode workspace in your project by
   running `open example/ios/ExtensionExample.xcworkspace` in a terminal window from your
   AgoraMarketplace project directory.
1. Select the device you intend to deploy to in the device drop-down menu next to the run button.
1. Select the `ExtensionExample` project in the left navigation panel.
1. In the `ExtensionExample` target settings page, make sure your Development Team is selected
   under **Signing & Capabilities > Team**.

   When you select a team, Xcode creates and downloads a Development Certificate, registers your
   device with your account, and creates and downloads a provisioning profile (if needed).

    * To start your first iOS development project, you might need to sign into Xcode with your Apple
      ID. ![Xcode account add](docs/images/xcode-account.png){:.mw-100} Development and testing is
      supported for any Apple ID. Enrolling in the Apple Developer Program is required to distribute
      your app to the App Store. For details about membership types,
      see [Choosing a Membership](https://developer.apple.com/support/compare-memberships).

   <a name="trust"></a>
    * The first time you use an attached physical device for iOS development, you need to trust both
      your Mac and the Development Certificate on that device. Select `Trust` in the dialog prompt
      when first connecting the iOS device to your Mac.

      ![Trust Mac](docs/images/trust-computer.png){:.mw-100}

      Then, go to the Settings app on the iOS device, select **General > Device Management**
      and trust your Certificate. For first time users, you may need to select
      **General > Profiles > Device Management** instead.

    * If automatic signing fails in Xcode, verify that the project's
      **General > Identity > Bundle Identifier** value is unique.
      ![Check the app's Bundle ID](docs/images/xcode-unique-bundle-id.png){:.mw-100}

</li>

<li markdown="1">

Start your app by clicking the Run button in Xcode.

</li>
</ol>
