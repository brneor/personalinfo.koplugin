<p align="center"><img src="assets/icon.png" width="160" height="160" alt="Personal Info icon: contact card with an open book"></p>

# Personal Information Widget for ZenOS

**Make your e-reader identifiable.** Add your name, contact details, and a custom recovery message to your ZenOS Home screen in KOReader.

An unofficial, independently maintained [ZenOS](https://github.com/xZenLabs/zen-os) Home widget for [KOReader](https://github.com/koreader/koreader). It displays the device owner's name and contact details, useful for identifying a lost e-reader.

> **Compatibility:** built against the external Home-widget API in ZenOS **4.3.1**. The ZenOS settings integration uses runtime hooks because that version does not expose a public external-widget settings API. Later ZenOS releases might require changes. Not yet verified on physical Kindle hardware.

**Repository description:**
> Customizable owner and contact information widget for ZenOS Home in KOReader.

## Features

- Show the owner's name, email address and phone number, with each field optional.
- Configure a customizable “If found, please contact” message.
- Independently choose font family, size, and bold style for the name and contact details.
- Choose left, center, or right alignment.
- Edit through **Zen Settings → Home → Widgets → Informações pessoais**, or long-press the widget with ZenOS Home Edit mode enabled.
- Keep settings outside the plugin folder so updates do not overwrite your data.

## Install

1. Download the ZIP from [Releases](../../releases), or clone this repository.
2. Place the `personalinfo.koplugin` directory into your KOReader plugins directory:
   - **Kindle:** `/mnt/base-us/koreader/plugins/`
   - **Kobo:** `/mnt/onboard/.adds/koreader/plugins/`
   - **Android:** `sdcard/koreader/plugins/`
3. Restart KOReader.
4. Go to **Zen Settings → Home → Widgets**. Enable **Informações pessoais** and open its settings submenu.

Final installation layout:

```text
koreader/plugins/
└── personalinfo.koplugin/
    ├── _meta.lua
    └── main.lua
```

## Configuration & privacy

Name, email, phone number, message, font preferences, and alignment are all configured inside KOReader; **no personal contact information is hardcoded in the plugin**.

Settings are stored in:

```text
koreader/settings/personalinfo.lua
```

This file lives outside `personalinfo.koplugin`, is not included in the repository, and should not be committed. No network service is used by this plugin. Information placed on the Home widget is visible to anyone who can view that screen.

The widget is part of the **ZenOS Home**, not the native Kindle sleep/lock screen.

## Branding

- [`assets/icon.png`](assets/icon.png) — square 512px monochrome icon (transparent background), suitable for GitHub previews and ZenPM presentation.
- [`assets/icon-128.png`](assets/icon-128.png) — compact variant.
- [`assets/icon.svg`](assets/icon.svg) — scalable, simplified outline suitable for e-ink UI themes.

The GitHub repository's **About → Description** should use the description above. The ZenPM scraper reads the repository description; it does not use the plugin's `_meta.lua` description for catalog text.

**Catalog icon caveat:** ZenPM does not currently auto-import an upstream repository's `assets/icon.png` as its `icon_url`. This repository supplies the artwork, but the default catalog may require a separate metadata/asset contribution in [`xZenLabs/repo`](https://github.com/xZenLabs/repo) to show a custom icon.

## ZenPM catalog compatibility

This public repository is named `personalinfo.koplugin`, meeting ZenPM's
KOReader-plugin name discovery rule without requiring GitHub topics. For automatic
inclusion in the default ZenPM catalog, the repository must also have at least
**5 GitHub stars**, recent activity (within 730 days), remain unarchived, and not
collide with an existing package ID. Discovery runs about hourly. The release ZIP
contains `personalinfo.koplugin/` at its root; this layout is recommended over
relying on GitHub's source archive fallback.

## Releases

Release ZIP files contain `personalinfo.koplugin/` at the root. Maintainers can create releases by pushing a tag such as `v1.2.0`; the GitHub Actions workflow packages the plugin and creates a GitHub Release.

## Development

Source files are under [`personalinfo.koplugin/`](personalinfo.koplugin). The plugin uses KOReader Lua APIs and ZenOS's `__ZENOS_REGISTER_HOME_ITEM` integration hook. To present its settings alongside built-in widgets in ZenOS 4.3.1, it wraps the Home settings dispatcher and arrange-menu function at runtime, restoring those functions when the plugin closes. ZenOS source files are never modified.

## License

[GNU General Public License v3.0](LICENSE).

---

## Português

**Descrição curta:** Widget de identificação pessoal e contato personalizável para a tela inicial do ZenOS no KOReader.


Widget de informações pessoais para a tela inicial do ZenOS no KOReader. Permite configurar nome, e-mail, telefone, mensagem de recuperação, família e tamanho das fontes, negrito e alinhamento, sem modificar o código-fonte.

**Instalação no Kindle:** copie a pasta `personalinfo.koplugin` para `/mnt/base-us/koreader/plugins/`, reinicie o KOReader e abra **Zen Settings → Home → Widgets → Informações pessoais**. Habilite o widget e configure os campos pelo submenu. Com o modo de edição do ZenOS habilitado, também é possível segurar o widget na tela inicial para abrir suas configurações.

As preferências ficam em `koreader/settings/personalinfo.lua`, preservadas quando o plugin é atualizado. O widget **não** altera a tela de bloqueio/suspensão nativa do Kindle.
