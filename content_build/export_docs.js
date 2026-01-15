/**
 * export_docs.js
 * 
 * Exports HTML from Docusaurus build output and creates self-contained HTML files
 * for offline mobile app consumption. Extracts article content and adds inline styles.
 * 
 * Usage: node export_docs.js
 */

const fs = require('fs');
const path = require('path');
const { JSDOM } = require('jsdom');

// Paths
const REPO_ROOT = path.resolve(__dirname, '..');
const WEBSITE_DIR = path.join(REPO_ROOT, 'website');
const BUILD_DIR = path.join(WEBSITE_DIR, 'build');
const DOCS_BUILD_DIR = path.join(BUILD_DIR, 'docs');
const CONTENT_DIR = path.join(REPO_ROOT, 'content');
const CONTENT_DOCS_DIR = path.join(CONTENT_DIR, 'docs');
const REGISTRY_PATH = path.join(__dirname, 'doc_registry.json');

/**
 * Inline CSS styles for offline reading
 */
const INLINE_STYLES = `
<style>
* { box-sizing: border-box; margin: 0; padding: 0; }
body { 
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
    line-height: 1.6; 
    color: #1a1a1a; 
    background: #fff;
    padding: 16px;
    max-width: 100%;
    font-size: 16px;
}
h1 { font-size: 1.8em; margin: 0.5em 0; color: #1a1a1a; }
h2 { font-size: 1.5em; margin: 1em 0 0.5em; color: #2a2a2a; border-bottom: 1px solid #eee; padding-bottom: 0.3em; }
h3 { font-size: 1.25em; margin: 1em 0 0.5em; color: #3a3a3a; }
h4, h5, h6 { font-size: 1.1em; margin: 1em 0 0.5em; }
p { margin: 0.8em 0; }
a { color: #0066cc; text-decoration: none; }
a:hover { text-decoration: underline; }
ul, ol { margin: 0.8em 0; padding-left: 1.5em; }
li { margin: 0.3em 0; }
code { 
    background: #f4f4f4; 
    padding: 2px 6px; 
    border-radius: 4px; 
    font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
    font-size: 0.9em;
}
pre { 
    background: #282c34; 
    color: #abb2bf; 
    padding: 16px; 
    border-radius: 8px; 
    overflow-x: auto; 
    margin: 1em 0;
}
pre code { background: none; padding: 0; color: inherit; }
blockquote { 
    border-left: 4px solid #0066cc; 
    margin: 1em 0; 
    padding: 0.5em 1em; 
    background: #f8f9fa;
}
table { 
    border-collapse: collapse; 
    width: 100%; 
    margin: 1em 0;
    overflow-x: auto;
    display: block;
}
th, td { 
    border: 1px solid #ddd; 
    padding: 8px 12px; 
    text-align: left; 
}
th { background: #f4f4f4; font-weight: 600; }
tr:nth-child(even) { background: #fafafa; }
img { max-width: 100%; height: auto; border-radius: 8px; margin: 1em 0; }
hr { border: none; border-top: 1px solid #eee; margin: 2em 0; }
.hash-link { display: none; }

/* Unit Navigation Footer */
.rl-unit-nav {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 16px;
    margin: 24px 0 8px;
    background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
    border-radius: 12px;
    border: 1px solid #dee2e6;
}
.rl-unit-nav a {
    display: inline-flex;
    align-items: center;
    padding: 10px 16px;
    background: #fff;
    border-radius: 8px;
    color: #0066cc;
    font-weight: 500;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    transition: all 0.2s ease;
}
.rl-unit-nav a:hover {
    background: #0066cc;
    color: #fff;
    text-decoration: none;
    transform: translateY(-1px);
    box-shadow: 0 4px 8px rgba(0,102,204,0.3);
}
.rl-unit-nav a.disabled {
    opacity: 0.4;
    pointer-events: none;
}

/* Backlinks Block */
.rl-backlinks {
    margin: 24px 0;
    padding: 16px;
    background: #f0f7ff;
    border-radius: 12px;
    border-left: 4px solid #0066cc;
}
.rl-backlinks h3 {
    margin: 0 0 12px;
    font-size: 1em;
    color: #0066cc;
}
.rl-backlinks ul {
    margin: 0;
    padding-left: 20px;
}
.rl-backlinks li {
    margin: 8px 0;
}
</style>
`;

/**
 * Load the doc registry
 */
function loadRegistry() {
    if (!fs.existsSync(REGISTRY_PATH)) {
        throw new Error(`doc_registry.json not found at ${REGISTRY_PATH}`);
    }
    return JSON.parse(fs.readFileSync(REGISTRY_PATH, 'utf-8'));
}

/**
 * Walk a directory and find all HTML files
 */
function findAllHtmlFiles(dir, basePath = dir) {
    const results = [];
    
    if (!fs.existsSync(dir)) return results;
    
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    
    for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);
        
        if (entry.isDirectory()) {
            results.push(...findAllHtmlFiles(fullPath, basePath));
        } else if (entry.isFile() && entry.name === 'index.html') {
            const relativePath = path.relative(basePath, fullPath).replace(/\\/g, '/');
            results.push({
                absolutePath: fullPath,
                relativePath,
                slug: path.dirname(relativePath).replace(/\\/g, '/')
            });
        }
    }
    
    return results;
}

/**
 * Extract article content from Docusaurus HTML and create clean HTML
 * @param {string} html - Raw HTML from Docusaurus build
 * @param {Map} routeToDocId - Map of routes to docIds for link rewriting
 * @param {string} docId - Current document ID
 * @param {Object} relations - Relations object with nextPrev data
 * @param {Object} backlinks - Backlinks for this doc (optional)
 */
function extractAndCleanHtml(html, routeToDocId, docId = null, relations = null, backlinks = null) {
    const dom = new JSDOM(html);
    const doc = dom.window.document;
    
    // Try to find the main article content
    let article = doc.querySelector('article');
    if (!article) {
        // Fallback: try to find main content area
        article = doc.querySelector('.theme-doc-markdown') || 
                  doc.querySelector('.markdown') ||
                  doc.querySelector('main');
    }
    
    if (!article) {
        // Last resort: use body but strip nav/footer
        article = doc.body;
        // Remove unwanted elements
        article.querySelectorAll('nav, footer, .navbar, .sidebar, .pagination-nav, .tocCollapsible, .tableOfContents').forEach(el => el.remove());
    }
    
    // Get title
    let title = 'Document';
    const h1 = article.querySelector('h1');
    if (h1) {
        title = h1.textContent.trim();
    } else {
        const titleEl = doc.querySelector('title');
        if (titleEl) {
            title = titleEl.textContent.split('|')[0].trim();
        }
    }
    
    // Rewrite ALL internal links starting with /docs/ to app://doc/docId
    const anchors = article.querySelectorAll('a[href]');
    for (const anchor of anchors) {
        let href = anchor.getAttribute('href');
        if (!href) continue;
        
        // Skip external links, anchors, mailto, tel
        if (href.startsWith('http://') || href.startsWith('https://') ||
            href.startsWith('#') || href.startsWith('mailto:') || 
            href.startsWith('tel:')) {
            continue;
        }
        
        // Convert /docs/... paths to docIds directly
        if (href.startsWith('/docs/') || href.startsWith('/docs\\')) {
            // Remove /docs/ prefix and trailing slash
            let path = href.replace(/^\/docs\//, '').replace(/\/$/, '');
            
            // Generate docId using same logic as file export
            const targetDocId = path
                .replace(/[/\\]/g, '_')
                .replace(/[^a-zA-Z0-9_]/g, '_')
                .replace(/_+/g, '_')
                .replace(/^_|_$/g, '')
                .toLowerCase();
            
            const fragment = href.includes('#') ? href.substring(href.indexOf('#')) : '';
            anchor.setAttribute('href', `app://doc/${targetDocId}${fragment}`);
            continue;
        }
        
        // Try routeToDocId lookup for other paths
        let targetPath = href.replace(/\/$/, '');
        const mappedDocId = routeToDocId.get(targetPath) || 
                      routeToDocId.get(targetPath.toLowerCase()) ||
                      routeToDocId.get(decodeURIComponent(targetPath));
        
        if (mappedDocId) {
            const fragment = href.includes('#') ? href.substring(href.indexOf('#')) : '';
            anchor.setAttribute('href', `app://doc/${mappedDocId}${fragment}`);
        }
    }
    
    // Remove images with absolute paths (they won't work offline)
    article.querySelectorAll('img[src^="/"]').forEach(img => {
        // Keep the alt text as a placeholder
        const alt = img.getAttribute('alt') || 'Image';
        const placeholder = doc.createElement('span');
        placeholder.textContent = `[${alt}]`;
        placeholder.style.cssText = 'display: block; padding: 20px; background: #f0f0f0; text-align: center; color: #666; border-radius: 8px; margin: 1em 0;';
        img.replaceWith(placeholder);
    });
    
    // Remove script tags
    article.querySelectorAll('script').forEach(el => el.remove());
    
    // Remove data-* attributes and complex class names for cleaner HTML
    article.querySelectorAll('*').forEach(el => {
        // Keep element but remove complex classes
        const className = el.getAttribute('class');
        if (className && className.includes('_')) {
            el.removeAttribute('class');
        }
    });
    
    // Get article content
    let articleContent = article.innerHTML;
    
    // Inject Unit Navigation Footer if relations exist
    let unitNavHtml = '';
    if (docId && relations && relations.nextPrev && relations.nextPrev[docId]) {
        const rel = relations.nextPrev[docId];
        const prevLink = rel.prev 
            ? `<a href="app://doc/${rel.prev}">⬅ Prev</a>` 
            : `<a class="disabled">⬅ Prev</a>`;
        const upLink = rel.up 
            ? `<a href="app://doc/${rel.up}">⬆ Notes</a>` 
            : '';
        const nextLink = rel.next 
            ? `<a href="app://doc/${rel.next}">Next ➡</a>` 
            : `<a class="disabled">Next ➡</a>`;
        
        unitNavHtml = `
<hr/>
<div class="rl-unit-nav">
  ${prevLink}
  ${upLink}
  ${nextLink}
</div>`;
    }
    
    // Inject Backlinks Block if they exist
    let backlinksHtml = '';
    if (docId && backlinks && backlinks[docId] && backlinks[docId].length > 0) {
        const links = backlinks[docId]
            .map(bl => `<li><a href="app://doc/${bl.targetDocId}">${bl.label}</a></li>`)
            .join('\n');
        backlinksHtml = `
<div class="rl-backlinks">
  <h3>📚 Related</h3>
  <ul>
    ${links}
  </ul>
</div>`;
    }
    
    // Build clean HTML document
    const cleanHtml = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${title}</title>
${INLINE_STYLES}
</head>
<body>
${articleContent}
${backlinksHtml}
${unitNavHtml}
</body>
</html>`;
    
    return cleanHtml;
}

/**
 * Build route lookup for link rewriting
 */
function buildRouteLookup(registry) {
    const routeToDocId = new Map();
    
    for (const [docId, meta] of Object.entries(registry)) {
        const sourcePath = meta.source
            .replace(/^website[\\/]docs[\\/]/, '/docs/')
            .replace(/[\\/]index\.mdx$/, '')
            .replace(/\.mdx$/, '');
        
        routeToDocId.set(sourcePath, docId);
        routeToDocId.set(sourcePath.toLowerCase(), docId);
        routeToDocId.set(encodeURI(sourcePath), docId);
    }
    
    return routeToDocId;
}
/**
 * Build relations (prev/next/up) from exported docIds
 * Groups units by course and generates sequential navigation
 */
function buildRelationsFromExport(exportedDocIds) {
    const nextPrev = {};
    const courseUnits = {};
    
    // Find all unit docs and group by course
    for (const { docId, source } of exportedDocIds) {
        // Detect if this is a unit doc (contains unit1, unit2, etc.)
        const unitMatch = docId.match(/unit(\d+)/i) || docId.match(/_u(\d+)$/);
        if (!unitMatch) continue;
        
        const unitNumber = parseInt(unitMatch[1], 10);
        
        // Extract course identifier (everything before _notes_unit or similar)
        let course = docId.replace(/_notes_unit\d+.*$/i, '').replace(/_unit\d+.*$/i, '').replace(/_u\d+.*$/i, '');
        if (!course) continue;
        
        if (!courseUnits[course]) {
            courseUnits[course] = [];
        }
        
        courseUnits[course].push({
            docId,
            number: unitNumber
        });
    }
    
    // Generate prev/next/up for each course
    for (const [course, units] of Object.entries(courseUnits)) {
        // Sort by unit number
        units.sort((a, b) => a.number - b.number);
        
        // Find the notes index for this course
        const notesIndex = findNotesIndexFromExport(course, exportedDocIds);
        
        for (let i = 0; i < units.length; i++) {
            const unit = units[i];
            nextPrev[unit.docId] = {
                prev: i > 0 ? units[i - 1].docId : null,
                next: i < units.length - 1 ? units[i + 1].docId : null,
                up: notesIndex
            };
        }
    }
    
    return { nextPrev };
}

/**
 * Find notes index for a course from exported docs
 */
function findNotesIndexFromExport(course, exportedDocIds) {
    // Try to find: course_notes or course_notes_index
    for (const { docId } of exportedDocIds) {
        // Match patterns like semester_1_c_programming_notes
        if (docId === `${course}_notes` || docId === `${course}_notes_index`) {
            return docId;
        }
    }
    
    // Fallback: find any notes doc that starts with course
    for (const { docId } of exportedDocIds) {
        if (docId.startsWith(course) && docId.includes('_notes') && !docId.match(/unit\d+/i)) {
            return docId;
        }
    }
    
    return null;
}

/**
 * Main export function
 */
async function exportDocs() {
    console.log('🚀 Starting docs export...');
    
    if (!fs.existsSync(BUILD_DIR)) {
        throw new Error(`Docusaurus build not found at ${BUILD_DIR}`);
    }
    
    // Load registry
    const registry = loadRegistry();
    console.log(`📚 Loaded ${Object.keys(registry).length} docs from registry`);
    
    // Find all HTML files in build
    const htmlFiles = findAllHtmlFiles(DOCS_BUILD_DIR);
    console.log(`📄 Found ${htmlFiles.length} HTML files in build`);
    
    // Build route lookup
    const routeToDocId = buildRouteLookup(registry);
    
    // Ensure output directory exists
    if (!fs.existsSync(CONTENT_DOCS_DIR)) {
        fs.mkdirSync(CONTENT_DOCS_DIR, { recursive: true });
    }
    
    // First pass: export all HTML and build docId list
    let successCount = 0;
    let failCount = 0;
    const exported = {};
    const exportedDocIds = [];
    
    for (const htmlFile of htmlFiles) {
        try {
            // Generate docId from path
            let docId = htmlFile.slug
                .replace(/[/\\]/g, '_')
                .replace(/[^a-zA-Z0-9_]/g, '_')
                .replace(/_+/g, '_')
                .replace(/^_|_$/g, '')
                .toLowerCase();
            
            if (!docId) docId = 'root';
            
            exportedDocIds.push({
                docId,
                htmlFile,
                source: htmlFile.relativePath
            });
            
        } catch (e) {
            console.error(`❌ Error processing ${htmlFile.relativePath}:`, e.message);
            failCount++;
        }
    }
    
    // Build relations from exported docs
    const relations = buildRelationsFromExport(exportedDocIds);
    console.log(`↔️  Built relations for ${Object.keys(relations.nextPrev).length} unit docs`);
    
    // Second pass: export HTML with relations
    for (const { docId, htmlFile, source } of exportedDocIds) {
        try {
            // Read and process HTML with relations
            const rawHtml = fs.readFileSync(htmlFile.absolutePath, 'utf-8');
            const cleanHtml = extractAndCleanHtml(rawHtml, routeToDocId, docId, relations, null);
            
            // Write output
            const outputPath = path.join(CONTENT_DOCS_DIR, `${docId}.html`);
            fs.writeFileSync(outputPath, cleanHtml, 'utf-8');
            
            exported[docId] = {
                source: source,
                output: `${docId}.html`
            };
            
            successCount++;
            console.log(`✅ Exported ${docId}`);
        } catch (e) {
            console.error(`❌ Error exporting ${docId}:`, e.message);
            failCount++;
        }
    }
    
    // Update registry with enhanced categorization
    const updatedRegistry = {};
    for (const [docId, info] of Object.entries(exported)) {
        const meta = extractDocMeta(docId, info.source);
        updatedRegistry[docId] = {
            title: meta.title,
            semester: meta.semester,
            subject: meta.subject,
            category: meta.category,
            unit: meta.unit,
            isHub: meta.isHub,
            order: meta.order,
            source: info.source
        };
    }
    
    fs.writeFileSync(REGISTRY_PATH, JSON.stringify(updatedRegistry, null, 4), 'utf-8');
    console.log(`✏️  Updated registry with ${Object.keys(updatedRegistry).length} entries`);
    
    console.log('\n📊 Export Summary:');
    console.log(`   ✅ Success: ${successCount}`);
    console.log(`   ❌ Failed: ${failCount}`);
    
    return { successCount, failCount, errors: [] };
}

/**
 * Extract enhanced metadata from docId and source path
 */
function extractDocMeta(docId, source) {
    const lowerDocId = docId.toLowerCase();
    const lowerSource = source.toLowerCase().replace(/\\/g, '/');
    
    // Extract semester
    let semester = 0;
    const semMatch = lowerDocId.match(/semester_?(\d+)/);
    if (semMatch) semester = parseInt(semMatch[1], 10);
    
    // Extract subject name
    let subject = extractSubjectName(docId, source);
    
    // Determine category and isHub
    let category = 'content';
    let isHub = false;
    let unit = null;
    let order = 0;
    
    // Check for unit pages first (most specific)
    const unitMatch = lowerDocId.match(/unit[_-]?(\d+)/i) || lowerSource.match(/unit[_-]?(\d+)/i);
    if (unitMatch) {
        category = 'unit';
        unit = parseInt(unitMatch[1], 10);
        order = unit;
    }
    // Check for handout
    else if (lowerDocId.includes('handout') || lowerSource.includes('/handout')) {
        category = 'handout';
        order = 1;
    }
    // Check for notes index (not a unit page)
    else if (lowerDocId.includes('notes')) {
        if (lowerSource.endsWith('/index.html') || lowerDocId.endsWith('_notes')) {
            category = 'notesIndex';
            isHub = true;
            order = 2;
        } else {
            category = 'notes';
            order = 2;
        }
    }
    // Check for assignments
    else if (lowerDocId.includes('assignment') || lowerSource.includes('/assignment')) {
        category = 'assignments';
        order = 3;
    }
    // Check for misc
    else if (lowerDocId.includes('misc') || lowerSource.includes('/misc')) {
        category = 'misc';
        order = 4;
    }
    // Check for PYQ
    else if (lowerDocId.includes('pyq') || lowerSource.includes('/pyq')) {
        category = 'pyq';
        order = 5;
    }
    // Check for projects
    else if (lowerDocId.includes('project') || lowerSource.includes('/project')) {
        category = 'projects';
        order = 6;
    }
    // Check for subject index
    else if (isSubjectIndex(lowerDocId, lowerSource)) {
        category = 'subjectIndex';
        isHub = true;
        order = 0;
    }
    // Check for semester index
    else if (isSemesterIndex(lowerDocId, lowerSource)) {
        category = 'semesterIndex';
        isHub = true;
        order = 0;
    }
    
    // Generate title
    const title = generateTitle(docId, category, unit, subject);
    
    return { title, semester, subject, category, unit, isHub, order };
}

function isSubjectIndex(docId, source) {
    const parts = docId.split('_');
    if (parts.length === 3 && parts[0] === 'semester' && !isNaN(parseInt(parts[1]))) {
        return true;
    }
    if (source.match(/semester[_\s]?\d+\/[^/]+\/index\.html$/i)) {
        return true;
    }
    return false;
}

function isSemesterIndex(docId, source) {
    return docId.match(/^semester_?\d+$/i) || source.match(/semester[_\s]?\d+\/index\.html$/i);
}

function extractSubjectName(docId, source) {
    const pathMatch = source.replace(/\\/g, '/').match(/semester[_\s]?\d+\/([^/]+)/i);
    if (pathMatch) {
        return pathMatch[1].replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
    }
    const parts = docId.split('_');
    if (parts.length >= 3 && parts[0] === 'semester') {
        return parts[2].replace(/\b\w/g, c => c.toUpperCase());
    }
    return 'General';
}

function generateTitle(docId, category, unit, subject) {
    if (category === 'unit' && unit) {
        return `Unit ${unit}`;
    }
    if (category === 'handout') return 'Handout';
    if (category === 'notesIndex') return 'Notes';
    if (category === 'assignments') return 'Assignments';
    if (category === 'misc') return 'Misc';
    if (category === 'pyq') return 'PYQ';
    if (category === 'projects') return 'Projects';
    if (category === 'subjectIndex' && subject) return subject;
    
    return docId.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
        .replace(/Pyq/g, 'PYQ').replace(/Cfoa/g, 'CFOA').replace(/Dld/g, 'DLD');
}

// Run if called directly
if (require.main === module) {
    exportDocs()
        .then(({ successCount, failCount }) => {
            if (failCount > 0 && successCount === 0) {
                process.exit(1);
            }
        })
        .catch((err) => {
            console.error('Fatal error:', err);
            process.exit(1);
        });
}

module.exports = { exportDocs, loadRegistry };
