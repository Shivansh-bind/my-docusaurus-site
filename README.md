# 📚 IMPACT Reference Library
> A clean, student-friendly Semester 2 library built with Docusaurus and deployed on Vercel.

---

## 🌟 What is this?
**IMPACT Reference Library** is an open-source academic reference website for students.
It includes:
- 📘 Unit-wise notes
- 📄 Handouts and PDF resources
- 🗓️ Datesheets and exam-related information
- 📰 News / announcements for latest uploads

Built using **Docusaurus** (docs + blog) and deployed on **Vercel**. :contentReference[oaicite:1]{index=1}

---

## 🔗 Live Website
➡️ **Production Site:** YOUR_VERCEL_URL

---

## ✨ Features
- ✅ Semester-wise subject structure (Semester 2)
- ✅ Unit-wise notes (easy for revision)
- ✅ Handouts hosted in `static/handouts`
- ✅ News / announcements using Docusaurus blog
- ✅ PR workflow with Vercel Preview Deployments
- ✅ Fast navigation + mobile-friendly layout

---

## 📁 Project Structure (Quick Overview)

```txt
my-docusaurus-site/
├─ docs/                       # Semester wise documentation
│  └─ Semester 2/
│     ├─ Computer Programming – II/
│     ├─ Discrete Mathematics/
│     ├─ Linux & Shell Programming/
│     ├─ Statistics/
│     ├─ Functional English/
│     ├─ Technical Report Writing/
│     └─ Multimedia System/
├─ blog/                       # News/Announcements
├─ static/
│  └─ handouts/                # PDFs (handouts, date sheets)
├─ src/pages/
│  └─ index.mdx                # Homepage
├─ sidebars.js                 # Sidebar config
├─ docusaurus.config.js        # Main config
└─ package.json
👥 Team & Credits
🏆 Owner
Shiwansh Bind

✨ Contributors
Dhananjay Assaulter

Rahul Sutteri

Contributions include docs, layout improvements, bug fixes, and content updates.

🚀 Getting Started (Run Locally)
✅ Requirements
Node.js (recommended: Node 20 LTS)

npm

Install
bash
Copy code
npm install
Start development server
bash
Copy code
npm start
Website runs at:

arduino
Copy code
http://localhost:3000
Build production site
bash
Copy code
npm run build
🤝 Contributing
We use a PR workflow:

No one pushes directly to main

Create a branch → commit → PR → Vercel Preview → merge

📌 Read the full guide:
➡️ CONTRIBUTING.md

✅ Deployment (Vercel)
This project is deployed on Vercel.

PRs generate Preview Deployments

main branch generates the Production Deployment

Vercel Deploy documentation: 
Vercel
+1

📜 License
This repository is open-source under the MIT License (or update as required).
See: LICENSE

❤️ Support
If you find this useful:

⭐ Star this repository

🧠 Suggest improvements via Issues

✅ Contribute notes/handouts formatting

yaml
Copy code

Badges use Shields.io (standard). :contentReference[oaicite:3]{index=3}

---

# 2) ✅ `CONTRIBUTING.md` (Team PR guide + pipelines + approvals)

Create: `CONTRIBUTING.md`

```md
# 🤝 Contributing Guide (Team Workflow)

Welcome! This guide explains exactly how to contribute without breaking the live website.

---

## ✅ Golden Rules
1. **Never push directly to `main`**
2. **One task = one branch**
3. **Always create a Pull Request (PR)**
4. **Test using Vercel Preview before requesting merge**
5. Keep PRs small and focused

---

## 🧠 How our pipeline works (simple)
Think of `main` as the final published book.
You edit on your own copy (branch), then request merging.

Branch → Pull Request → Preview Deployment → Review → Merge → Production Deploy

yaml
Copy code

---

## 🔀 Step-by-step workflow

### 1) Sync your project with main
```bash
git checkout main
git pull origin main
2) Create a branch
bash
Copy code
git checkout -b docs/add-sem2-datesheet
🏷️ Branch naming rules
Use one of these prefixes:

docs/ → docs, notes, handouts, datesheets

fix/ → broken links, build issues

feature/ → new sections/pages

chore/ → cleanup

Examples:

docs/add-cp2-unit1-notes

fix/broken-assignments-links

feature/semester2-layout

3) Make your changes and test locally
bash
Copy code
npm start
4) Commit messages (fast approval format)
We use:

scss
Copy code
type(scope): short message
✅ Allowed types

docs → notes/handouts/datesheets

fix → broken links/build issues

feat → new page/section

style → formatting only

chore → cleanup

✅ Examples:

docs(cp2): add unit 1 notes and PDF links

fix(links): remove broken assignments route

feat(home): add semester 2 quick buttons

5) Push your branch
bash
Copy code
git push -u origin docs/add-sem2-datesheet
🔍 Open a Pull Request (PR)
On GitHub:

Pull Requests → New Pull Request

Base: main

Compare: your branch

Fill PR template carefully

👀 Preview Deployments (important)
Once PR is created, Vercel automatically creates a Preview Deployment link. 
GitHub
+1

✅ Before asking for merge, test:

sidebar navigation

pages open correctly

PDFs open correctly

no broken links

✅ Pipelines / Checks explained (noob friendly)
When PR is opened, checks run automatically:

Build check: Docusaurus can build site?

Broken links check: do all internal links exist?

Preview deploy: Vercel preview is generated?

If any check fails: ❌ No merge.
Fix and push again.

🧾 PR Approval Checklist
To get quick approval:

✅ correct branch name

✅ good commit message

✅ preview tested

✅ no broken links

✅ PR description filled

Thank you for contributing! ✨

yaml
Copy code

---

# 3) ✅ PR Template (auto appears when opening PR)

Create file: `.github/PULL_REQUEST_TEMPLATE.md`

```md
## ✅ What did you change?
- 

## 🎯 Why is this needed?
- 

## 🧪 What should the reviewer test?
- [ ] Sidebar navigation works
- [ ] Pages open correctly
- [ ] PDF links work
- [ ] No broken links

## 🔗 Preview Deployment Link (Vercel)
Paste preview link here:
-
4) ✅ Issue Templates (Make repo feel organized)
Create folder:
.github/ISSUE_TEMPLATE/

bug_report.md
md
Copy code
---
name: Bug report
about: Report an issue or broken page
title: "[BUG] "
labels: bug
assignees: ''
---

## What happened?
-

## Steps to reproduce
1.
2.
3.

## Expected behavior
-

## Screenshots (if any)
-
feature_request.md
md
Copy code
---
name: Feature request
about: Suggest improvements or new content structure
title: "[FEATURE] "
labels: enhancement
assignees: ''
---

## What do you want to add?
-

## Why is it useful?
-

## Any references/links?
-
