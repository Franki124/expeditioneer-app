import 'package:flutter/material.dart';

import '../../core/widgets/motion.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

/// RODO (GDPR) information clause shown to guests who sign in with Google,
/// as required by art. 13 RODO when collecting personal data from the user.
///
/// TODO(Michał): fill in the data controller before release.
class PrivacyNotice {
  PrivacyNotice._();

  /// Who decides about the data: a person, company or the convent.
  static const controllerName = '[NAZWA ADMINISTRATORA]';

  /// Where guests send RODO requests (access, correction, deletion).
  static const controllerEmail = '[ADRES E-MAIL DO SPRAW DANYCH]';

  static const title = 'Ochrona danych osobowych (RODO)';

  static const summary =
      'Logując się przez Google, przekazujesz nam swoją nazwę, adres e-mail i zdjęcie '
      'profilowe z konta Google. Administratorem danych jest $controllerName. '
      'Używamy ich wyłącznie do prowadzenia Twojego konta i udziału w grze, a Twoja '
      'nazwa i wynik są widoczne w rankingu wydarzenia. Masz prawo dostępu do danych, '
      'ich poprawienia i usunięcia. Jeśli nie chcesz podawać adresu e-mail, możesz '
      'grać jako gość.';

  static const profileNote =
      'Przechowujemy Twój adres e-mail i dane z konta Google, aby prowadzić Twoje '
      'konto w grze. Aby uzyskać do nich dostęp lub je usunąć, napisz na '
      '$controllerEmail.';

  static const sections = <(String, String)>[
    (
      'Administrator danych',
      'Administratorem Twoich danych osobowych jest $controllerName. '
          'We wszystkich sprawach dotyczących danych możesz pisać na $controllerEmail.',
    ),
    (
      'Jakie dane przetwarzamy',
      'Z konta Google: nazwę wyświetlaną, adres e-mail, zdjęcie profilowe i identyfikator '
          'konta. Z gry: wydarzenia, do których dołączasz, zeskanowane kody, odpowiedzi '
          'w zadaniach i zdobyte punkty.',
    ),
    (
      'Cel i podstawa prawna',
      'Prowadzenie Twojego konta i umożliwienie udziału w grze, w tym wyświetlanie '
          'Twojej nazwy i wyniku w rankingu wydarzenia (art. 6 ust. 1 lit. b RODO). '
          'Odpowiadanie na Twoje zgłoszenia oraz ewentualne ustalenie, dochodzenie lub '
          'obrona roszczeń, co jest naszym prawnie uzasadnionym interesem '
          '(art. 6 ust. 1 lit. f RODO).',
    ),
    (
      'Odbiorcy danych',
      'Dane są przechowywane w usłudze Google Firebase (Google Ireland Ltd. i Google LLC), '
          'która działa na nasze zlecenie jako podmiot przetwarzający. Twoja nazwa '
          'i wynik są widoczne dla innych uczestników tego samego wydarzenia.',
    ),
    (
      'Przekazywanie poza EOG',
      'Google LLC może przetwarzać dane w Stanach Zjednoczonych. Odbywa się to na podstawie '
          'decyzji Komisji Europejskiej w sprawie EU-US Data Privacy Framework oraz '
          'standardowych klauzul umownych.',
    ),
    (
      'Jak długo przechowujemy dane',
      'Do czasu usunięcia konta. Po otrzymaniu Twojego żądania usunięcia usuwamy dane '
          'bez zbędnej zwłoki, chyba że musimy je zachować w celu obrony roszczeń.',
    ),
    (
      'Twoje prawa',
      'Masz prawo dostępu do swoich danych, ich sprostowania, usunięcia, ograniczenia '
          'przetwarzania i przenoszenia, a także prawo sprzeciwu wobec przetwarzania '
          'opartego na prawnie uzasadnionym interesie. Masz też prawo wnieść skargę '
          'do Prezesa Urzędu Ochrony Danych Osobowych (ul. Stawki 2, 00-193 Warszawa).',
    ),
    (
      'Dobrowolność',
      'Podanie danych jest dobrowolne, ale bez nich nie zalogujesz się przez Google. '
          'Możesz grać jako gość bez podawania adresu e-mail. Nie podejmujemy wobec '
          'Ciebie decyzji w sposób zautomatyzowany i nie profilujemy Cię.',
    ),
  ];
}

/// Shows the short RODO notice before Google sign-in or account linking.
/// Returns true only when the guest chose to continue.
Future<bool> confirmGooglePrivacyNotice(BuildContext context) async {
  final accepted = await showAppDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.navyPanel2,
      title: Text(PrivacyNotice.title, style: AppTypography.body(fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              PrivacyNotice.summary,
              style: AppTypography.body(color: AppColors.creamDim, fontSize: 15),
            ),
            const SizedBox(height: AppSpacing.xs8),
            TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => showPrivacyNoticeDetails(dialogContext),
              child: const Text('Pełna klauzula informacyjna'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Anuluj'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Rozumiem, kontynuuj'),
        ),
      ],
    ),
  );
  return accepted ?? false;
}

/// Shows the full art. 13 RODO information clause.
Future<void> showPrivacyNoticeDetails(BuildContext context) {
  return showAppDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.navyPanel2,
      title: Text(
        'Klauzula informacyjna RODO',
        style: AppTypography.body(fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (heading, body) in PrivacyNotice.sections) ...[
              Text(heading, style: AppTypography.body(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: AppSpacing.xs4),
              Text(body, style: AppTypography.body(color: AppColors.creamDim, fontSize: 14)),
              const SizedBox(height: AppSpacing.sm12),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Zamknij'),
        ),
      ],
    ),
  );
}
