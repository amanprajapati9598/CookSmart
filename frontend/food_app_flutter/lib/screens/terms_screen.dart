import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

    // We can define English and Hindi text directly or use a dummy text representing T&C
    final isHindi = lang.currentLanguage == 'Hindi';

    final text = isHindi
        ? '''कुकिंग स्मार्ट ऐप में आपका स्वागत है।

1. स्वीकृति: हमारे ऐप का उपयोग करके, आप इन नियमों और शर्तों से सहमत होते हैं।
2. उपयोगकर्ता खाता: आपको सुरक्षा और सही जानकारी के लिए अपना ईमेल और नाम दर्ज करना पड़ सकता है।
3. सामग्री: इस ऐप में मौजूद सभी रेसिपी और सामग्री केवल सूचनात्मक और व्यक्तिगत उपयोग के लिए है।
4. गोपनीयता: हम आपकी गोपनीयता का सम्मान करते हैं। आपकी खोज हिस्ट्री और प्राथमिकताओं को बेहतर अनुभव के लिए सहेजा जाता है।
5. बदलाव: हम समय-समय पर इन नियमों में संशोधन कर सकते हैं।

धन्यवाद।'''
        : '''Welcome to the Cooking Smart App.

1. Acceptance: By using our app, you agree to these terms and conditions.
2. User Account: You may be required to register with an email and name for security and accurate recommendations.
3. Content: All recipes and materials provided inside this app are for informational and personal use only.
4. Privacy: We respect your privacy. Your search history and preferences are saved locally to provide a better experience.
5. Modifications: We reserve the right to amend these terms from time to time.

Thank you.''';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(lang.t('terms_conditions'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 1,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          text,
          style: TextStyle(fontSize: 16, height: 1.5, color: textColor),
        ),
      ),
    );
  }
}
