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
 */
function extractAndCleanHtml(html, routeToDocId) {
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
    
    // Rewrite links
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
        
        // Try to match to a docId
        let targetPath = href.replace(/\/$/, '');
        
        // Look up docId
        const docId = routeToDocId.get(targetPath) || 
                      routeToDocId.get(targetPath.toLowerCase()) ||
                      routeToDocId.get(decodeURIComponent(targetPath));
        
        if (docId) {
            const fragment = href.includes('#') ? href.substring(href.indexOf('#')) : '';
            anchor.setAttribute('href', `app://doc/${docId}${fragment}`);
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
${article.innerHTML}
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
    
    // Export all HTML files
    let successCount = 0;
    let failCount = 0;
    const exported = {};
    
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
            
            // Read and process HTML
            const rawHtml = fs.readFileSync(htmlFile.absolutePath, 'utf-8');
            const cleanHtml = extractAndCleanHtml(rawHtml, routeToDocId);
            
            // Write output
            const outputPath = path.join(CONTENT_DOCS_DIR, `${docId}.html`);
            fs.writeFileSync(outputPath, cleanHtml, 'utf-8');
            
            exported[docId] = {
                source: htmlFile.relativePath,
                output: `${docId}.html`
            };
            
            successCount++;
            console.log(`✅ Exported ${docId}`);
        } catch (e) {
            console.error(`❌ Error exporting ${htmlFile.relativePath}:`, e.message);
            failCount++;
        }
    }
    
    // Update registry
    const updatedRegistry = {};
    for (const [docId, info] of Object.entries(exported)) {
        updatedRegistry[docId] = {
            title: docId.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase()),
            semester: docId.includes('semester_1') ? 1 : docId.includes('semester_2') ? 2 : 0,
            subject: extractSubject(docId),
            type: extractType(docId),
            order: 0,
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

function extractSubject(docId) {
    const parts = docId.split('_');
    if (parts.length >= 2) {
        return parts.slice(1, -1).join(' ').replace(/\b\w/g, c => c.toUpperCase());
    }
    return 'General';
}

function extractType(docId) {
    if (docId.includes('handout')) return 'handout';
    if (docId.includes('notes')) return 'notes';
    if (docId.includes('pyq')) return 'pyq';
    if (docId.includes('index')) return 'index';
    return 'content';
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
