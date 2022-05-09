import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:args/src/utils.dart';

abstract class CommandOptions {
  ArgParser getArgParser();
}

abstract class Command<T extends CommandOptions> extends BaseCommand<void> {
  late T commandOptions;

  @override
  ArgParser get argParser => commandOptions.getArgParser();

  bool get deprecated => false;

  /// The path to send to Google Analytics. Return null here to disable
  /// tracking of the command.
  Future<String> get usagePath async {
    if (parent is Command) {
      final Command commandParent = parent as Command;
      final String path = await commandParent.usagePath;
      // Don't report for parents that return null for usagePath.
      return '$path/$name';
    } else {
      return name;
    }
  }

  /// Parses [args] and returns the result, converting an [ArgParserException]
  /// to a [UsageException].
  ///
  /// This is notionally a protected method. It may be overridden or called from
  /// subclasses, but it shouldn't be called externally.
  ArgResults parse(List<String> args);

  /// Runs this command.
  ///
  /// Rather than overriding this method, subclasses should override
  /// [verifyThenRunCommand] to perform any verification
  /// and [runCommand] to execute the command
  /// so that this method can record and report the overall time to analytics.
  @override
  Future<void> run(List<String> args) async {
    _argResults = parse(args);
    final String commandPath = await usagePath;
    return await verifyThenRunCommand(commandPath);
  }

  /// Perform validation then call [runCommand] to execute the command.
  /// Return a [Future] that completes with an exit code
  /// indicating whether execution was successful.
  ///
  /// Subclasses should override this method to perform verification
  /// then call this method to execute the command
  /// rather than calling [runCommand] directly.
  Future<void> verifyThenRunCommand(String commandPath) async {
    await validateCommand();
    return runCommand();
  }

  /// Subclasses must implement this to execute the command.
  /// Optionally provide a [FlutterCommandResult] to send more details about the
  /// execution for analytics.
  Future<void> runCommand();

  Future<void> validateCommand() async {}

  @override
  String get usage {
    final String usageWithoutDescription = super.usage.substring(
          // The description plus two newlines.
          description.length + 2,
        );
    final String help = <String>[
      if (deprecated)
        'Deprecated. This command will be removed in a future version of AgoraMarketplace.',
      description,
      '',
      'Global options:',
      argParser.usage,
      '',
      usageWithoutDescription,
    ].join('\n');
    return help;
  }
}

/// A single command.
///
/// A command is known as a "leaf command" if it has no subcommands and is meant
/// to be run. Leaf commands must override [run].
///
/// A command with subcommands is known as a "branch command" and cannot be run
/// itself. It should call [addSubcommand] (often from the constructor) to
/// register subcommands.
abstract class BaseCommand<T> {
  /// The name of this command.
  String get name;

  /// A description of this command, included in [usage].
  String get description;

  /// A short description of this command, included in [parent]'s
  /// [CommandRunner.usage].
  ///
  /// This defaults to the first line of [description].
  String get summary => description.split('\n').first;

  /// A single-line template for how to invoke this command (e.g. `"pub get
  /// `package`"`).
  String get invocation {
    var parents = [name];
    for (var command = parent; command != null; command = command.parent) {
      parents.add(command.name);
    }

    var invocation = parents.reversed.join(' ');
    return _subcommands.isNotEmpty
        ? '$invocation <subcommand> [arguments]'
        : '$invocation [arguments]';
  }

  /// The command's parent command, if this is a subcommand.
  ///
  /// This will be `null` until [addSubcommand] has been called with
  /// this command.
  BaseCommand<T>? get parent => _parent;
  BaseCommand<T>? _parent;

  /// The parsed global argument results.
  ///
  /// This will be `null` until just before [Command.run] is called.
  ArgResults? get globalResults => _globalResults;
  ArgResults? _globalResults;

  /// The parsed argument results for this command.
  ///
  /// This will be `null` until just before [Command.run] is called.
  ArgResults? get argResults => _argResults;
  ArgResults? _argResults;

  /// The argument parser for this command.
  ///
  /// Options for this command should be registered with this parser (often in
  /// the constructor); they'll end up available via [argResults]. Subcommands
  /// should be registered with [addSubcommand] rather than directly on the
  /// parser.
  ///
  /// This can be overridden to change the arguments passed to the `ArgParser`
  /// constructor.
  ArgParser get argParser => _argParser;
  final _argParser = ArgParser();

  /// Generates a string displaying usage information for this command.
  ///
  /// This includes usage for the command's arguments as well as a list of
  /// subcommands, if there are any.
  String get usage => _wrap('$description\n\n') + _usageWithoutDescription;

  /// An optional footer for [usage].
  ///
  /// If a subclass overrides this to return a string, it will automatically be
  /// added to the end of [usage].
  String? get usageFooter => null;

  String _wrap(String text, {int? hangingIndent}) {
    return wrapText(text,
        length: argParser.usageLineLength, hangingIndent: hangingIndent);
  }

  /// Returns [usage] with [description] removed from the beginning.
  String get _usageWithoutDescription {
    var length = argParser.usageLineLength;
    var usagePrefix = 'Usage: ';
    var buffer = StringBuffer()
      ..writeln(
          usagePrefix + _wrap(invocation, hangingIndent: usagePrefix.length))
      ..writeln(argParser.usage);

    if (_subcommands.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(_getCommandUsage(
        _subcommands,
        isSubcommand: true,
        lineLength: length,
      ));
    }

    buffer.writeln();
    buffer.write(_wrap('Run "help" to see global options.'));

    if (usageFooter != null) {
      buffer.writeln();
      buffer.write(_wrap(usageFooter!));
    }

    return buffer.toString();
  }

  /// An unmodifiable view of all sublevel commands of this command.
  Map<String, BaseCommand<T>> get subcommands =>
      UnmodifiableMapView(_subcommands);
  final _subcommands = <String, BaseCommand<T>>{};

  /// Whether or not this command should be hidden from help listings.
  ///
  /// This is intended to be overridden by commands that want to mark themselves
  /// hidden.
  ///
  /// By default, leaf commands are always visible. Branch commands are visible
  /// as long as any of their leaf commands are visible.
  bool get hidden {
    // Leaf commands are visible by default.
    if (_subcommands.isEmpty) return false;

    // Otherwise, a command is hidden if all of its subcommands are.
    return _subcommands.values.every((subcommand) => subcommand.hidden);
  }

  /// Whether or not this command takes positional arguments in addition to
  /// options.
  ///
  /// If false, [CommandRunner.run] will throw a [UsageException] if arguments
  /// are provided. Defaults to true.
  ///
  /// This is intended to be overridden by commands that don't want to receive
  /// arguments. It has no effect for branch commands.
  bool get takesArguments => true;

  /// Alternate names for this command.
  ///
  /// These names won't be used in the documentation, but they will work when
  /// invoked on the command line.
  ///
  /// This is intended to be overridden.
  List<String> get aliases => const [];

  Command() {
    if (!argParser.allowsAnything) {
      argParser.addFlag('help',
          abbr: 'h', negatable: false, help: 'Print this usage information.');
    }
  }

  /// Runs this command.
  ///
  /// The return value is wrapped in a `Future` if necessary and returned by
  /// [CommandRunner.runCommand].
  FutureOr<T>? run(List<String> args) {
    throw UnimplementedError(_wrap('Leaf command $this must implement run().'));
  }

  /// Adds [Command] as a subcommand of this.
  void addSubcommand(BaseCommand<T> command) {
    var names = [command.name, ...command.aliases];
    for (var name in names) {
      _subcommands[name] = command;
      argParser.addCommand(name, command.argParser);
    }
    command._parent = this;
  }

  /// Prints the usage information for this command.
  ///
  /// This is called internally by [run] and can be overridden by subclasses to
  /// control how output is displayed or integrate with a logging system.
  void printUsage() => print(usage);

  /// Throws a [UsageException] with [message].
  Never usageException(String message) =>
      throw UsageException(_wrap(message), _usageWithoutDescription);
}

/// Returns a string representation of [commands] fit for use in a usage string.
///
/// [isSubcommand] indicates whether the commands should be called "commands" or
/// "subcommands".
String _getCommandUsage(Map<String, BaseCommand> commands,
    {bool isSubcommand = false, int? lineLength}) {
  // Don't include aliases.
  var names =
      commands.keys.where((name) => !commands[name]!.aliases.contains(name));

  // Filter out hidden ones, unless they are all hidden.
  var visible = names.where((name) => !commands[name]!.hidden);
  if (visible.isNotEmpty) names = visible;

  // Show the commands alphabetically.
  names = names.toList()..sort();
  var length = names.map((name) => name.length).reduce(math.max);

  var buffer = StringBuffer('Available ${isSubcommand ? "sub" : ""}commands:');
  var columnStart = length + 5;
  for (var name in names) {
    var lines = wrapTextAsLines(commands[name]!.summary,
        start: columnStart, length: lineLength);
    buffer.writeln();
    buffer.write('  ${padRight(name, length)}   ${lines.first}');

    for (var line in lines.skip(1)) {
      buffer.writeln();
      buffer.write(' ' * columnStart);
      buffer.write(line);
    }
  }

  return buffer.toString();
}
