import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:tool/src/commands/command.dart';

part 'build_command_options.g.dart';

@CliOptions()
class BuildCommandOptions extends CommandOptions {
  @CliOption(
    abbr: 't',
    allowed: ['aar', 'apk', 'framework', 'app', 'ipa'],
    allowedHelp: {
      'aar': 'Build a repository containing an AAR and a POM file.',
      'apk': 'Build an Android APK file from your app.',
      'framework':
          'Produces .xcframeworks for a AgoraMarketplace project and its plugins for integration into existing, plain Xcode projects.',
      'ipa': 'Build an iOS archive bundle (Mac OS X host only).',
    },
  )
  final String? target;

  @CliOption(
    name: 'export-options-plist',
    help:
        'Optionally export an IPA with these options. See "xcodebuild -h" for available exportOptionsPlist keys.',
  )
  final String? exportOptionsPlist;

  @CliOption(abbr: 'v', defaultsTo: false, help: 'Print additional event types')
  final bool? verbose;

  @CliOption(
      abbr: 'f',
      help: 'The format to display. Defaults to '
          '"Friday, October 18 at 13:55 PM: <User> opened <URL>"',
      allowed: ['default', 'markdown'])
  final String? format;

  @CliOption(abbr: 'h', negatable: false, help: 'Prints usage information.')
  final bool help;

  BuildCommandOptions(
    this.target,
    this.exportOptionsPlist,
    this.verbose,
    this.format,
    this.help,
  );

  @override
  ArgParser getArgParser() {
    return _$parserForBuildCommandOptions;
  }
}
