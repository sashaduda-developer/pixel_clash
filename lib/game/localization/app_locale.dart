/// Поддерживаемые языки.
/// Сейчас RU + EN (как пример), но игра по умолчанию русская.
enum AppLocale {
  ru,
  en;

  String get code => switch (this) {
        AppLocale.ru => 'ru',
        AppLocale.en => 'en',
      };
}
