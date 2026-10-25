# Claude Code themes

The site and the Claude Code plugin marketplace at
<https://themes.whirlwin.io>. A theme is a Claude Code mod that takes over
the spinner while Claude works. Each theme is a plugin in its own repo; this
repo holds the catalog that lists them and the page that shows them.

| Theme | Plugin | Repo |
| --- | --- | --- |
| Halloween | `halloween` | [whirlwin/claude-code-halloween](https://github.com/whirlwin/claude-code-halloween) |
| Hacker News | `hackernews` | [whirlwin/claude-code-hackernews](https://github.com/whirlwin/claude-code-hackernews) |
| VG | `vg` | [whirlwin/claude-code-vg](https://github.com/whirlwin/claude-code-vg) |

Add the marketplace in a Claude Code session, then install a theme:

```
/plugin marketplace add https://themes.whirlwin.io/marketplace.json
/plugin install halloween@whirlwin-themes
```

From a shell, the first line is
`claude plugin marketplace add https://themes.whirlwin.io/marketplace.json`.

## Layout

| Path | What it is |
| --- | --- |
| `.claude-plugin/marketplace.json` | The catalog, and its only copy in git |
| `wrangler.jsonc` | The Worker: static assets only, no code, on themes.whirlwin.io |
| `public/` | The site: plain HTML and CSS, no framework and no build step |
| `public/index.html` | The page, with one card per theme |
| `public/404.html` | Served for any path that has no file |
| `public/copy.js` | The copy buttons, the only script on the site |
| `public/_headers` | Security headers for every response, plus the content type, cache and CORS headers for `/marketplace.json` |
| `public/images/` | The themes' pictures, copied from each repo's `docs/`, the whirlwin.io wordmark and the grain overlay |
| `public/fonts/` | JetBrains Mono and its license (OFL), served by the site so the CSP allows no other origin |
| `public/og.png` | The link preview picture, rendered from `og/card.html` |
| `og/card.html` | The source of `og.png`, not deployed |
| `scripts/check.sh` | The consistency check that `npm run check` runs |

The look (colors, the card with its window dots, the status bar and the
scanlines) comes from [whirlwin.io](https://whirlwin.io), so the two sites read
as one family. Each theme card adds its own accent color.

### How /marketplace.json is served

The catalog lives in `.claude-plugin/marketplace.json`, where
`claude plugin validate .` looks for it. The `build.command` in
`wrangler.jsonc` copies it to `public/marketplace.json`. Wrangler runs that
command before `wrangler dev` and before `wrangler deploy`, so the site always
serves the same bytes as the file in git. The copy is gitignored, so there is
nothing to keep in sync by hand.

Workers Builds, Cloudflare's deploy-from-git service, does not run
`build.command`. If you connect this repo to it, set its build command to
`cp .claude-plugin/marketplace.json public/marketplace.json`, or the deployed
site has no `/marketplace.json`.

### Caching

Workers static assets send every file with
`Cache-Control: public, max-age=0, must-revalidate` and an ETag, so browsers
check for a new version each time and the pages need no version query
strings. `/marketplace.json` is the exception: `_headers` gives it
`max-age=300`, so an update to the catalog reaches users within five minutes.

## Local preview

```sh
npm install
npm run dev
```

Open <http://localhost:8787>. Editing a file in `public/` or the catalog
reloads the server; the catalog edit is copied into `public/` first.

## Check

```sh
npm run check
```

It runs `claude plugin validate .`, then `scripts/check.sh`, which fails when:

- a catalog entry has no card on the page, or a card has no entry
- a card does not show `/plugin install <name>@whirlwin-themes`
- a `src`, `href`, CSS `url()` or `og:image` points at a file that is not in
  `public/`, or at an `id` the page does not have
- a file in this repo that we write has an en or em dash

The script needs `jq`, which macOS ships with.

## Deploy

```sh
npm run deploy
```

That runs `wrangler deploy`, which copies the catalog into `public/` first.
themes.whirlwin.io is a custom domain on the whirlwin.io zone in the same
Cloudflare account, so the first deploy creates the DNS record and the
certificate. The `*.workers.dev` URL and preview URLs are off. Log in once
with `npx wrangler login`.

## Add a theme

1. Add an entry to `.claude-plugin/marketplace.json`. Its `name` is the
   plugin's name from its own `plugin.json`. Give it a `description`, a
   `homepage`, a `category`, `tags` and a `url` source with the repo's https
   clone URL. Leave out `version`: the plugin's `plugin.json` already has one,
   and when both are set `claude plugin validate` warns that they disagree.
2. Add a card to `public/index.html`. Copy one of the
   `<article class="card theme ...">` elements and set its `id` to the plugin
   name. Give it the install command, the theme's own commands, a link to its
   repo, and its pictures, copied into `public/images/` and described in `alt`
   text. Add a `.theme--<name>` rule to `styles.css` with its `--accent`
   color, plus a lighter `--accent-text` if the accent has less than 4.5:1
   contrast on the dark background. Add the theme to the status bar too.
3. Run `npm run check`, then `npm run deploy`.

People who already added the marketplace see the new theme after
`claude plugin marketplace update whirlwin-themes`.

## Why url sources

People add this marketplace by its URL, and for a marketplace added that way
Claude Code downloads only `marketplace.json`. A relative source such as
`./plugins/halloween` has nothing to resolve against, so every entry has to
name a repository of its own. A `github` source needs a GitHub SSH key, or
`CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1`, to clone. A `url` source with the https
clone URL of a public repo needs nothing.

## Link preview

`og.png` is `og/card.html` screenshotted at exactly 1200x627. The card loads
its pictures from `/public/...`, so serve the repo root, not `public/`:

```sh
python3 -m http.server 8790
```

Open <http://localhost:8790/og/card.html> in a browser with a 1200x627
viewport at 1x, take a screenshot and save it as `public/og.png`.

## Submissions

Third-party themes are deliberately not open yet. The catalog lists only
whirlwin's own themes, and the site has no submission form, sign-in or
database.

Not affiliated with Anthropic, Y Combinator or Hacker News, or VG.
