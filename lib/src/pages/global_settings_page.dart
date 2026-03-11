import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common_widgets.dart';
import '../l10n.dart';
import '../models.dart';

class GlobalSettingsPage extends StatefulWidget {
  const GlobalSettingsPage({super.key});
  @override
  State<GlobalSettingsPage> createState() => _GlobalSettingsPageState();
}

class _GlobalSettingsPageState extends State<GlobalSettingsPage> {
  bool _notification = false;
  bool _widgetSync = false;

  void _showWip(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ac(ctx).card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          ctx.l10n.featureInDevelopmentTitle,
          style: TextStyle(
            color: ac(ctx).primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          ctx.l10n.featureInDevelopmentMessage,
          style: TextStyle(color: kHint, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              ctx.l10n.okAction,
              style: const TextStyle(color: kAccent),
            ),
          ),
        ],
      ),
    );
  }

  String _localeModeLabel(BuildContext context, String mode) {
    final l10n = context.l10n;
    switch (mode) {
      case kLocaleModeChineseSimplified:
        return l10n.languageForceChineseSimplified;
      case kLocaleModeChineseTraditional:
        return l10n.languageForceChineseTraditional;
      case kLocaleModeEnglish:
        return l10n.languageForceEnglish;
      case kLocaleModeJapanese:
        return l10n.languageForceJapanese;
      default:
        return l10n.languageFollowSystem;
    }
  }

  void _showLanguagePicker(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ac(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final options = [
          kLocaleModeSystem,
          kLocaleModeChineseSimplified,
          kLocaleModeChineseTraditional,
          kLocaleModeEnglish,
          kLocaleModeJapanese,
        ];
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.languageSettingLabel,
                style: const TextStyle(
                  color: Color(0xFF1C1C1E),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...options.map(
                (mode) => GestureDetector(
                  onTap: () {
                    appState.updateLocaleMode(mode);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 4,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: kDivider, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _localeModeLabel(context, mode),
                          style: TextStyle(
                            color: mode == appState.localeMode
                                ? const Color(0xFF4ECDC4)
                                : ac(context).primaryText,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        if (mode == appState.localeMode)
                          const Icon(
                            Icons.check,
                            color: Color(0xFF4ECDC4),
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    return SubPageScaffold(
      title: context.l10n.globalSettingsTitle,
      children: [
        settingCard(context, [
          SettingRow(
            label: context.l10n.darkMode,
            trailing: Switch(
              value: appState.isDarkMode,
              onChanged: (v) => appState.updateDarkMode(v),
              activeColor: const Color(0xFF4ECDC4),
            ),
          ),
          SettingRow(
            label: context.l10n.languageSettingLabel,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _localeModeLabel(context, appState.localeMode),
                  style: const TextStyle(color: kHint, fontSize: 13),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: kHint, size: 18),
              ],
            ),
            onTap: () => _showLanguagePicker(context, appState),
          ),
          SettingRow(
            label: context.l10n.courseReminder,
            trailing: Switch(
              value: _notification,
              onChanged: (v) => _showWip(context),
              activeColor: const Color(0xFF4ECDC4),
            ),
          ),
          SettingRow(
            label: context.l10n.widgetSync,
            showDivider: false,
            trailing: Switch(
              value: _widgetSync,
              onChanged: (v) => _showWip(context),
              activeColor: const Color(0xFF4ECDC4),
            ),
          ),
        ]),
        settingCard(context, [
          SettingRow(
            label: context.l10n.setBackgroundFormat,
            showDivider: false,
            onTap: () => _showWip(context),
            trailing: const Icon(Icons.chevron_right, color: kHint, size: 18),
          ),
        ]),
        settingCard(context, [
          SettingRow(
            label: context.l10n.helpUsage,
            showDivider: false,
            trailing: const Icon(Icons.open_in_new, color: kHint, size: 16),
            onTap: () async {
              final uri = Uri.parse(
                'https://github.com/Shiroko114514/StayUP-Calendar',
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ]),
      ],
    );
  }
}
