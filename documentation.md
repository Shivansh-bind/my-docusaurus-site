Absolutely — now we’re in **“proper product spec / engineering documentation”** territory. 😄
I’ll give you a **revised, detailed documentation** where **UI/UX is lowest priority** and **core system logic + pipelines are highest priority**, exactly as you want.

This will be written so that later we can **attach any crazy UI/UX on top** without changing backend/logic.

---

# ReferenceLibrary v2 Documentation (Revised)

**Priority Order**

1. ✅ Core Architecture & Logic (Highest)
2. ✅ Content Pipeline (Docs → HTML → Releases → App)
3. ✅ Offline-first Storage + Update system
4. ✅ Reader + Navigation logic (App)
5. ✅ Progress tracking (optional Supabase)
6. ✅ Website integration (Docusaurus stays)
7. 🎨 UI/UX Layer (Lowest priority)

---

## 0) Why we are rebuilding from scratch

### Problems in current approach (Website WebView based)

* Docusaurus links produce **relative hrefs**, slug changes, encoding issues.
* Semester 1/2 folder names contain spaces, unicode dash, etc → breaks in mobile.
* WebView tries to resolve relative links incorrectly → redirects to website / 404.
* Offline support is weak.
* App depends too much on Docusaurus routing behavior.

### New solution (Correct design)

**The app must NOT depend on Docusaurus URLs.**
Instead, it should use:

✅ **Stable docId** for every doc
✅ Content exported to **HTML**
✅ Delivered to app via **GitHub Releases ZIP packs**
✅ App is **offline-first**
✅ Progress uses docId keys

---

# 1) Core Concepts

## 1.1 The docId system (fundamental)

Each document has:

* **docId** (stable unique key used everywhere)
* title (UI)
* metadata (semester, subject, order, tags)
* slug (web URL optional)
* html path (for app reader)

### Example

```yaml
docId: s1_cprog_handout
title: "📘 Handout"
semester: 1
subject: "C Programming"
type: "handout"
order: 1
slug: /s1/c-programming/handout
```

### docId naming rules

**Format**: `s{sem}_{subject}_{type}_{unitOrName}`

Examples:

* `s1_cprog_index`
* `s1_cprog_unit1`
* `s1_cprog_notes_arrays`
* `s2_dm_handout`
* `s2_linux_assignments_1`

Rules:

* lowercase
* only letters, numbers, underscore
* never changes once published (critical)

---

# 2) High Level System Architecture

## 2.1 Website vs App responsibilities

### Website (Docusaurus)

* Public facing browsing
* SEO
* Interactive website experience
* Can embed full MDX, React components, etc.

### Mobile App (Offline-first study tool)

* Does not rely on website routing
* Downloads “Study Assets Packs”
* Renders exported HTML locally
* Tracks progress
* (Optional) Sync progress

---

# 3) Content Pipeline (Most Important)

## 3.1 Source Content

You write content in:

* `.mdx` (your current Docusaurus docs)
* plus future interactive blocks (fill blanks, quizzes)

## 3.2 Output for app

Mobile app will render:
✅ **HTML pages** (not MDX)

Why HTML?

* WebView renders HTML perfectly
* Can add interactive bits easily (JS inside HTML)
* Supports offline (assets local)
* Same output everywhere

So pipeline becomes:

### Pipeline Flow

1. `docs/*.mdx` written in repo
2. Build export generates HTML for app
3. Build generates `index.json` manifest
4. Pack HTML + assets into ZIP
5. Upload ZIP + manifest to GitHub Release

---

## 3.3 Export system design

### Output folder structure (inside ZIP)

```
release_pack/
  index.json
  docs/
    s1_cprog_handout.html
    s1_cprog_unit1.html
    s2_dm_handout.html
  assets/
    img/
    css/
    js/
```

### Manifest `index.json` (single source of truth)

This is what the app loads first.

Example:

```json
{
  "packVersion": "2026.01.13",
  "generatedAt": "2026-01-13T12:00:00Z",
  "siteOrigin": "https://referencelibrary.vercel.app",
  "docs": {
    "s1_cprog_handout": {
      "title": "📘 Handout",
      "semester": 1,
      "subject": "C Programming",
      "type": "handout",
      "order": 1,
      "slug": "/s1/c-programming/handout",
      "html": "docs/s1_cprog_handout.html",
      "updatedAt": "2026-01-13"
    }
  },
  "tree": [
    {
      "id": "semester_1",
      "title": "Semester 1",
      "items": [
        {
          "id": "s1_cprog",
          "title": "C Programming",
          "items": [
            { "docId": "s1_cprog_index" },
            { "docId": "s1_cprog_handout" },
            { "docId": "s1_cprog_unit1" }
          ]
        }
      ]
    }
  ]
}
```

Important:

* `docs` is lookup table
* `tree` defines navigation UI (app can render any UI from it)

✅ This makes the app future-proof.

---

# 4) Link System (Critical for “page not found” issue)

## 4.1 Internal linking format (universal)

Inside docs, links must be written as:

* `doc:s1_cprog_handout`

NOT as:

* `/docs/Semester 1/C-Programming/Handout/index`

This is non-negotiable if you want perfect behavior.

---

## 4.2 During export: Convert doc links

When exporting to HTML:

Convert:

```md
[Handout](doc:s1_cprog_handout)
```

into HTML link like:

```html
<a href="app://doc/s1_cprog_handout">Handout</a>
```

OR

```html
<a href="/__app__/doc/s1_cprog_handout">Handout</a>
```

Then in WebView, intercept it.

---

## 4.3 Reader intercept rules (App)

When a link is clicked:

### Rules

1. If URL starts with `app://doc/` → open inside app Reader by docId
2. If URL is same-host (or internal) → open inside app if docId can be resolved
3. If URL is external (different host) → open browser via `url_launcher`
4. If file download (pdf/docx) → download & open locally (future)

This replaces the messy relative URL resolution problem permanently.

---

# 5) App Functional Architecture (Logic First)

## 5.1 App Modules

### Core

* Manifest Loader
* Pack Download Manager
* Cache/Storage Manager
* Doc Resolver
* Reader Engine
* Progress Tracker

### Feature modules

* Library navigation
* Search index
* Downloads
* Updates
* Sync (optional)

---

## 5.2 App startup flow (first install)

1. App opens
2. Checks if manifest exists locally
3. If not:

   * show “Get Study Assets” CTA
   * downloads latest ZIP pack from GitHub Releases
4. Extract to local storage
5. Build local indices
6. Render navigation from manifest tree

---

# 6) Offline First Download & Cache System

## 6.1 Why caching works perfectly here

Because:

* HTML lives locally
* All assets (CSS, JS, images) local
* WebView loads `file://...` or local server URL

Result:
✅ 0 loading time once downloaded

---

## 6.2 Update strategy (50+ students safe)

We need:

* low bandwidth
* no frequent re-download
* stable behavior

### Update mechanism

1. App fetches only **small release metadata**
2. Compares `packVersion`
3. If new:

   * download new pack
   * extract
   * replace old pack
   * keep progress database (separate storage)

Optional:

* delta updates later
* per-semester packs later

---

# 7) Progress Tracking & Sync

## 7.1 Without authentication

Without login, cross-device sync is **not reliably possible**.

You *can* do hacks like:

* device-to-device share export file
* QR code import/export progress JSON
  But true cross-device auto sync needs some identity.

---

## 7.2 Recommended: Supabase (free and fast)

### Why Supabase fits

* Free tier is generous
* Postgres is reliable
* Auth is simple
* Real-time optional
* Students can use OTP login

### Minimal Auth UX

Option A (easiest):

* phone OTP
  Option B:
* email magic link
  Option C:
* anonymous auth + upgrade later

---

## 7.3 What we store

Progress keys should always use docId.

Example progress model:

```json
{
  "userId": "xxx",
  "progress": {
    "s1_cprog_unit1": { "status": "completed", "lastRead": "2026-01-13" },
    "s2_dm_handout": { "status": "reading", "scroll": 0.72 }
  }
}
```

---

# 8) Docusaurus Website Integration (Not required for app)

The website remains your “public library”.

### Important website changes (to avoid broken links)

* Use `docId` linking inside docs: `doc:s1_cprog_handout`
* Ensure generated slugs are stable
* Home page links: must use encoded slugs OR generated slug constants

But the app will no longer break even if website slugs change, because app uses packs.

---

# 9) Interactivity inside App Docs (Option C)

You asked specifically:

✅ Interactive fill blanks + validate — in app

### How it works

Since app uses HTML:

* embed JS-driven quiz widgets

Example snippet:

```html
<div class="fill-blank" data-answer="opportunity cost">
  The cost of next best alternative is <input type="text" />
  <button onclick="checkAnswer(this)">Check</button>
  <span class="result"></span>
</div>

<script>
function checkAnswer(btn){
  const root = btn.closest('.fill-blank');
  const ans = root.dataset.answer.trim().toLowerCase();
  const val = root.querySelector('input').value.trim().toLowerCase();
  root.querySelector('.result').innerText = (val === ans) ? "✅ Correct" : "❌ Try again";
}
</script>
```

This will work:

* offline
* in WebView
* fast

Later we can standardize widgets.

---

# 10) Dangerous changes / possible damage if we restructure doc tree

You asked whether we need overhaul and potential damage.

## 10.1 What changes break things?

* Renaming docId (catastrophic)
* Removing docs referenced by others
* Changing manifest structure without versioning
* Changing asset paths without update

## 10.2 What can change safely?

* titles
* order
* tree structure
* category placements
* website slugs
* adding new docs

As long as docId stable.

---

# 11) Future scalability decisions (best for you)

You currently have:

* docs
* blogs
* news

We should treat them as content types.

Manifest structure can support multiple types:

```json
{
  "docs": {...},
  "blogs": {...},
  "news": {...}
}
```

Tree can include:

* Study Library
* News Feed
* Blogs

App can load only what is downloaded.

---

# 12) Minimal UI/UX notes (kept low priority)

UI must be “dumb” and driven by manifest.

Meaning:

* UI reads `tree`
* UI renders navigation
* UI triggers Reader

So later any UI redesign is safe.

---

# Summary (the architecture in 1 line)

**Docs → Export HTML + index.json → ZIP in GitHub Release → App downloads pack → Offline reader + docId-based navigation + optional Supabase sync**

---

If you want, next I can produce:
✅ a **step-by-step build plan** (commands + scripts + file structure + CI pipeline), written like an engineering checklist that your agent can execute with 0 confusion.

