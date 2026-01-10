const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const repoRoot = path.join(__dirname, "..");
const websiteDir = path.join(repoRoot, "website");
const docsDir = path.join(websiteDir, "docs");
const staticDir = path.join(websiteDir, "static");

const outputFile = path.join(websiteDir, "static", "app", "index.json");
const siteOrigin = "https://referencelibrary.vercel.app";

function safeReadDir(dir) {
  return fs.readdirSync(dir).sort((a, b) => a.localeCompare(b));
}

function isDir(p) {
  return fs.existsSync(p) && fs.statSync(p).isDirectory();
}
function isFile(p) {
  return fs.existsSync(p) && fs.statSync(p).isFile();
}

function toDocId(filePath) {
  // relative to docsDir, remove extension, normalize slashes
  const rel = path.relative(docsDir, filePath);
  return rel.replace(/\\/g, "/").replace(/\.mdx$/, "");
}

function encodeUrlPath(docIdOrPath) {
  return docIdOrPath
    .split("/")
    .map((seg) => encodeURIComponent(seg))
    .join("/");
}

function localKeyFromId(id) {
  return id.replace(/[\/\\]/g, "_").replace(/[^a-zA-Z0-9_]/g, "_");
}

function titleFromFilename(filename) {
  return filename
    .replace(/\.mdx$/, "")
    .replace(/[-_]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function fileMeta(filePath) {
  const stat = fs.statSync(filePath);
  const updatedAt = stat.mtime.toISOString();
  const sizeBytes = stat.size;
  // lightweight hash: mtime+size (fast) – good enough for incremental sync
  const hash = crypto
    .createHash("sha1")
    .update(`${updatedAt}:${sizeBytes}`)
    .digest("hex");

  return { updatedAt, sizeBytes, hash };
}

function listSemesters() {
  return safeReadDir(docsDir).filter((name) => isDir(path.join(docsDir, name)) && name.startsWith("Semester"));
}

function listSubjects(semesterDir) {
  return safeReadDir(semesterDir).filter((name) => isDir(path.join(semesterDir, name)));
}

function getSections(subjectDir) {
  // sections are either folders OR .mdx files (except index.mdx)
  const sections = {};
  const entries = safeReadDir(subjectDir);

  for (const entry of entries) {
    const entryPath = path.join(subjectDir, entry);

    if (isDir(entryPath)) {
      sections[entry] = entryPath;
      continue;
    }

    if (entry.endsWith(".mdx") && entry !== "index.mdx") {
      const sectionName = entry.replace(/\.mdx$/, "");
      sections[sectionName] = entryPath;
    }
  }
  return sections;
}

function getSectionItems(sectionPath) {
  const items = [];

  if (isFile(sectionPath)) {
    // section itself is a file
    const id = toDocId(sectionPath);
    const { updatedAt, sizeBytes, hash } = fileMeta(sectionPath);

    items.push({
      id,
      title: titleFromFilename(path.basename(sectionPath)),
      type: "html_doc",
      url: `${siteOrigin}/docs/${encodeUrlPath(id)}`,
      localKey: localKeyFromId(id),
      hash,
      updatedAt,
      sizeBytes,
    });
    return items;
  }

  // section is a directory: add all mdx files (sorted)
  const files = safeReadDir(sectionPath).filter((f) => f.endsWith(".mdx"));

  for (const f of files) {
    const filePath = path.join(sectionPath, f);
    const id = toDocId(filePath);
    const { updatedAt, sizeBytes, hash } = fileMeta(filePath);

    items.push({
      id,
      title: titleFromFilename(f),
      type: "html_doc",
      url: `${siteOrigin}/docs/${encodeUrlPath(id)}`,
      localKey: localKeyFromId(id),
      hash,
      updatedAt,
      sizeBytes,
    });
  }

  // OPTIONAL: put intro first if exists
  items.sort((a, b) => {
    if (a.id.endsWith("/intro") && !b.id.endsWith("/intro")) return -1;
    if (b.id.endsWith("/intro") && !a.id.endsWith("/intro")) return 1;
    return a.title.localeCompare(b.title);
  });

  return items;
}

function scanHandouts() {
  // Optional: scan PDFs from static/handouts/
  const handoutsDir = path.join(staticDir, "handouts");
  if (!isDir(handoutsDir)) return [];

  const results = [];

  function walk(dir) {
    for (const entry of safeReadDir(dir)) {
      const full = path.join(dir, entry);
      if (isDir(full)) walk(full);
      else if (entry.toLowerCase().endsWith(".pdf")) {
        const rel = path.relative(staticDir, full).replace(/\\/g, "/"); // handouts/...
        const { updatedAt, sizeBytes, hash } = fileMeta(full);
        const id = `static/${rel}`;

        results.push({
          id,
          title: titleFromFilename(entry),
          type: "pdf",
          url: `${siteOrigin}/${encodeUrlPath(rel)}`,
          localKey: localKeyFromId(id),
          hash,
          updatedAt,
          sizeBytes,
        });
      }
    }
  }

  walk(handoutsDir);

  return results;
}

function buildIndex() {
  const semesters = [];

  for (const semesterName of listSemesters()) {
    const semesterDir = path.join(docsDir, semesterName);
    const subjectNames = listSubjects(semesterDir);

    const subjects = subjectNames.map((subjectName) => {
      const subjectDir = path.join(semesterDir, subjectName);
      const sections = getSections(subjectDir);

      return {
        name: subjectName,
        sections: Object.keys(sections).map((sectionName) => {
          return {
            name: sectionName,
            items: getSectionItems(sections[sectionName]),
          };
        }),
      };
    });

    semesters.push({
      name: semesterName,
      subjects,
    });
  }

  const index = {
    appVersion: "1.0.0",
    generatedAt: new Date().toISOString(),
    announcements: {
      feedUrl: `${siteOrigin}/blog/rss.xml`,
      latestPosts: [],
    },
    handouts: scanHandouts(),
    semesters,
  };

  fs.mkdirSync(path.dirname(outputFile), { recursive: true });
  fs.writeFileSync(outputFile, JSON.stringify(index, null, 2));
  console.log("✅ Index generated at:", outputFile);
}

buildIndex();
