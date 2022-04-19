/// An indirection around our mustache templating system to avoid a
/// dependency on mustache..
abstract class TemplateRenderer {
  const TemplateRenderer();

  String renderString(String template, dynamic context,
      {bool htmlEscapeValues = false});
}
