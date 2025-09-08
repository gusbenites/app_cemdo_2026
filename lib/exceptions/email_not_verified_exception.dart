class EmailNotVerifiedException implements Exception {
  final String message;

  EmailNotVerifiedException([this.message = 'Email no verificado.']);

  @override
  String toString() => 'EmailNotVerifiedException: $message';
}
