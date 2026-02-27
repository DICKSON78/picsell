import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../providers/localization_provider.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  int? _expandedIndex;

  List<Map<String, String>> _getFAQs(bool isSwahili) {
    if (isSwahili) {
      return [
        {
          'question': 'PicSell ni nini?',
          'answer': 'PicSell ni programu ya simu inayokusaidia kubadilisha picha za bidhaa za kawaida kuwa picha za kuuza mara moja. Inafaa kwa WhatsApp, Instagram, na masoko ya mtandaoni - inaondoa background, inasafisha picha, na kufanya bidhaa zako zionekane kitaalamu - hakuna ujuzi unaohitajika.',
        },
        {
          'question': 'Nani anaweza kutumia PicSell?',
          'answer': 'Muuzaji yeyote, kuanzia biashara ndogo hadi brand kubwa, anaweza kutumia PicSell. Ukiposta bidhaa mtandaoni au unataka kuuza haraka, PicSell inafanya picha zako zionekane kuvutia zaidi kwa wanunuzi.',
        },
        {
          'question': 'Je, ninahitaji kamera ya kitaalamu?',
          'answer': 'Hapana! PicSell inafanya kazi na picha yoyote, hata iliyopigwa kwa simu rahisi. Piga picha bidhaa yako na uipakiwe - PicSell itafanya mengine.',
        },
        {
          'question': 'PicSell inagharimu kiasi gani?',
          'answer': 'PicSell inatumia mfumo wa krediti.\n1 krediti = picha 1 iliyochakatwa\nUnaweza kununua vifurushi (mf. picha 6 kwa TZS 5,000, picha 12 kwa TZS 10,000)\nUnaponunua zaidi, unapata thamani bora.\nKwa njia hii, unalipa tu picha unazohitaji - hakuna usajili wa bei kubwa kwa mwezi.',
        },
        {
          'question': 'Ninawezaje kulipa?',
          'answer': 'Unaweza kulipa kwa usalama kupitia:\n- M-Pesa\n- Tigo Pesa / Airtel Money\n- Malipo ya kadi (Visa/Mastercard)',
        },
        {
          'question': 'Inachukua muda gani kuchakata picha?',
          'answer': 'Picha nyingi zinachakatwa kwa sekunde hadi dakika chache, kulingana na ugumu wa picha. PicSell inafanya kazi kwa ufanisi hata kwa picha nyingi.',
        },
        {
          'question': 'Je, ninaweza kuchakata picha nyingi kwa wakati mmoja?',
          'answer': 'Ndiyo! Unaweza kupakia picha kadhaa kwa wakati mmoja na kuzichakata kama kundi. Programu itakata idadi sahihi ya krediti kiotomatiki.',
        },
        {
          'question': 'Je, PicSell itafanya kazi kwa bidhaa zote?',
          'answer': 'PicSell inafanya kazi vizuri kwa bidhaa za kimwili kama nguo, viatu, elektroniki, vipodozi, chakula, na zaidi. Huenda isifae kwa picha za sanaa au abstract.',
        },
        {
          'question': 'Je, ninaweza kuhariri picha baada ya PicSell kuzichakata?',
          'answer': 'Ndiyo! PicSell inaruhusu marekebisho ya msingi kama kukata, kuweka maandishi, na sticker - yote ni hiari. Thamani kuu ni picha safi zilizo tayari kuuza.',
        },
        {
          'question': 'Je, data yangu iko salama?',
          'answer': 'Kabisa. PicSell inatumia seva salama kuchakata picha. Picha zako zinatumika tu kuzalisha matokeo yaliyochakatwa na hazishiriki na watu wa nje.',
        },
        {
          'question': 'Je, ninahitaji mtandao kutumia PicSell?',
          'answer': 'Ndiyo, PicSell inahitaji muunganisho wa mtandao kuchakata picha kwa sababu uchakataji unafanyika kwenye wingu.',
        },
        {
          'question': 'Je, PicSell inaweza kunisaidia kuuza haraka?',
          'answer': 'Ndiyo! Picha za ubora wa juu zinavutia wanunuzi zaidi, zinaongeza imani, na kufanya orodha zako zionekane kwenye mitandao ya kijamii au masoko ya mtandaoni.',
        },
        {
          'question': 'Je, ninaweza kutumia PicSell kwa picha za kibinafsi au picha za uso?',
          'answer': 'Kwa sasa, PicSell inalenga picha za bidhaa. Picha za uso na picha za kibinafsi zinaweza kujumuishwa katika sasisho za baadaye.',
        },
        {
          'question': 'Je, kama sijaridhika na matokeo?',
          'answer': 'PicSell inatoa dhamana ya kuridhika. Ikiwa matokeo si kama ilivyotarajiwa, unaweza kutuma maoni kupitia programu, na timu yetu ya msaada itakusaidia.',
        },
        {
          'question': 'Je, ninaweza kutumia picha zilizochakatwa kwa masoko kama WhatsApp, Instagram, au Jiji?',
          'answer': 'Ndiyo! Mara picha imechakatwa, unaweza kuipakua na kuiposta popote, ikiwa ni pamoja na WhatsApp, Instagram, Jiji, Zoom, na majukwaa mengine.',
        },
      ];
    } else {
      return [
        {
          'question': 'What is PicSell?',
          'answer': 'PicSell is a mobile app that helps you turn ordinary product photos into selling-ready images instantly. Perfect for WhatsApp, Instagram, and online marketplaces, it removes backgrounds, cleans photos, and makes your products look professional - no skills required.',
        },
        {
          'question': 'Who can use PicSell?',
          'answer': 'Any seller, from small micro-businesses to bigger brands, can use PicSell. If you post products online or want to sell faster, PicSell makes your images look more attractive to buyers.',
        },
        {
          'question': 'Do I need a professional camera?',
          'answer': 'No! PicSell works with any photo, even taken from a simple phone. Just snap your product and upload it - PicSell will do the rest.',
        },
        {
          'question': 'How much does PicSell cost?',
          'answer': 'PicSell uses a credit-based system.\n1 credit = 1 processed image\nYou can buy bundles (e.g., 6 images for TZS 5,000, 12 images for TZS 10,000)\nThe more you buy, the better the value.\nThis way, you only pay for the images you need - no expensive monthly subscription.',
        },
        {
          'question': 'How do I pay?',
          'answer': 'You can pay securely via:\n- M-Pesa\n- Tigo Pesa / Airtel Money\n- Card payments (Visa/Mastercard)',
        },
        {
          'question': 'How long does it take to process a photo?',
          'answer': 'Most images are processed within seconds to a few minutes, depending on image complexity. PicSell works efficiently even for multiple images.',
        },
        {
          'question': 'Can I process multiple photos at once?',
          'answer': 'Yes! You can upload several images at once and process them as a batch. The app will deduct the correct number of credits automatically.',
        },
        {
          'question': 'Will PicSell work for all products?',
          'answer': 'PicSell works best for physical products like clothing, shoes, electronics, cosmetics, food, and more. It may not be suitable for abstract or artistic photos.',
        },
        {
          'question': 'Can I edit the photos after PicSell processes them?',
          'answer': 'Yes! PicSell allows basic adjustments like cropping, text overlay, and stickers - all optional. The main value is in ready-to-sell clean photos.',
        },
        {
          'question': 'Is my data safe?',
          'answer': 'Absolutely. PicSell uses secure servers to process photos. Your images are only used to generate the processed output and are not shared with third parties.',
        },
        {
          'question': 'Do I need internet to use PicSell?',
          'answer': 'Yes, PicSell requires an internet connection to process images because processing happens on the cloud.',
        },
        {
          'question': 'Can PicSell help me sell faster?',
          'answer': 'Yes! High-quality photos attract more buyers, increase trust, and make your listings stand out on social media or online marketplaces.',
        },
        {
          'question': 'Can I use PicSell for personal photos or portraits?',
          'answer': 'Currently, PicSell is focused on product photos. Portraits and personal images may be included in future updates.',
        },
        {
          'question': 'What if I\'m not happy with the result?',
          'answer': 'PicSell provides a satisfaction guarantee. If the output is not as expected, you can submit feedback through the app, and our support team will assist.',
        },
        {
          'question': 'Can I use processed photos for marketplaces like WhatsApp, Instagram, or Jiji?',
          'answer': 'Yes! Once the photo is processed, you can download and post it anywhere, including WhatsApp, Instagram, Jiji, Zoom, and other platforms.',
        },
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context);
    final faqs = _getFAQs(localization.isSwahili);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.arrow_back, color: AppTheme.text, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          localization.isSwahili ? 'Maswali Yanayoulizwa Mara kwa Mara' : 'Frequently Asked Questions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.text,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.help_outline, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PicSell FAQ',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          localization.isSwahili
                              ? 'Pata majibu ya maswali yako'
                              : 'Get answers to your questions',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withAlpha(200),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // FAQ List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: faqs.length,
              itemBuilder: (context, index) {
                final faq = faqs[index];
                final isExpanded = _expandedIndex == index;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isExpanded ? AppTheme.primaryColor : AppTheme.border,
                      width: isExpanded ? 2 : 1,
                    ),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _expandedIndex = expanded ? index : null;
                        });
                      },
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isExpanded
                              ? AppTheme.primaryColor
                              : AppTheme.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isExpanded ? Colors.white : AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        faq['question']!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.text,
                        ),
                      ),
                      trailing: Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppTheme.primaryColor,
                      ),
                      children: [
                        Text(
                          faq['answer']!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Contact support section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.support_agent,
                    size: 48,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localization.isSwahili
                        ? 'Bado una maswali?'
                        : 'Still have questions?',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localization.isSwahili
                        ? 'Timu yetu iko tayari kukusaidia'
                        : 'Our team is ready to help you',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/help'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          localization.isSwahili ? 'Wasiliana Nasi' : 'Contact Us',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
