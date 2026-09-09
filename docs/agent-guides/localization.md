# Localization

Use this reference when changing visible copy, translations, or localization behavior. Paths and API names in package instructions identify each UI's integration point.

- User-visible production text, including accessibility labels and errors, must use i18n keys. Preserve existing English source text byte-for-byte and keep existing English keys when migrating copy or translating, unless the user requests changing them.
- Treat the English dictionary as the semantic source of truth. Preserve placeholders, code identifiers, product/provider/tool names, URLs, asset names, and keyboard labels.
- Translate complete phrases in their UI context, using placeholders only for irreducible dynamic values. Do not concatenate grammatical fragments or select locale/plural variants in feature code.
- Keep locale selection, plural rules, fallback, and interpolation inside shared typed i18n APIs. Extend that layer when needed instead of adding grammar branches to components or IPC handlers.
- Reuse established project translations and terminology first. For unfamiliar or disputed terms, new locales, or grammar/plural changes, consult the relevant authority: Unicode CLDR, Microsoft/Apple localization guidance, Mozilla/Firefox/Pontoon, or the locale's language authority or dictionary.
- Prefer established developer terminology, including accepted English borrowings. Compare independent maintained corpora such as Firefox, KDE, or VS Code when the terminology is uncertain or sources disagree; do not require a fixed number of external sources for every string.
- For a focused change, review affected keys and related recurring terms. For delivery of a complete locale, check concept consistency and every value still equal to English; retain only intentional names, identifiers, keyboard legends, acronyms, assets, or established borrowings.
- Record consulted sources and unresolved regional or linguistic choices when they help review. Do not turn every small copy change into a full-language research report.
