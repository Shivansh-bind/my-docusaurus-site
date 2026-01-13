/**
 * export_docs.js
 * 
 * Exports HTML from Docusaurus build output and rewrites internal links
 * to use app://doc/<docId> scheme for offline mobile app consumption.
 * 
 * This version walks the build directory to find HTML files and matches
 * them back to the registry based on path similarity.
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
                // Slug derived from path (e.g., "Semester 1/C-Programming/Notes/unit1/index.html" -> "Semester-1/C-Programming/Notes/unit1")
                slug: path.dirname(relativePath).replace(/\\/g, '/')
            });
        }
    }
    
    return results;
}

/**
 * Build mappings between registry entries and HTML files
 */
function buildHtmlMapping(registry, htmlFiles) {
    const mapping = {};
    const unmatched = [];
    
    for (const [docId, meta] of Object.entries(registry)) {
        // Extract key parts from source path
        const sourcePath = meta.source
            .replace(/^website[\\/]docs[\\/]/, '')
            .replace(/\.mdx$/, '');
        
        // Try to find a matching HTML file
        let matched = null;
        
        // Strategy 1: Direct path match (for index.mdx files)
        if (sourcePath.endsWith('/index') || sourcePath.endsWith('\\index')) {
            const dirPath = path.dirname(sourcePath).replace(/\\/g, '/');
            matched = htmlFiles.find(h => h.slug === dirPath || h.slug.toLowerCase() === dirPath.toLowerCase());
        }
        
        // Strategy 2: Look for folder with similar name
        if (!matched) {
            const filename = path.basename(sourcePath);
            const dirname = path.dirname(sourcePath).replace(/\\/g, '/');
            
            // Look for HTML in a folder named similar to the file
            const candidates = htmlFiles.filter(h => {
                const hDir = path.dirname(h.slug).replace(/\\/g, '/');
                return hDir.toLowerCase() === dirname.toLowerCase() ||
                       h.slug.toLowerCase().startsWith(dirname.toLowerCase());
            });
            
            for (const candidate of candidates) {
                const candidateFolder = path.basename(candidate.slug).toLowerCase();
                // Match if the folder name contains part of the filename
                if (candidateFolder.includes(filename.toLowerCase().replace(/[^a-z0-9]/g, '').substring(0, 5))) {
                    matched = candidate;
                    break;
                }
            }
        }
        
        // Strategy 3: Fuzzy match on subject and semester
        if (!matched && meta.semester && meta.subject) {
            const subjectSlug = meta.subject.toLowerCase().replace(/[^a-z0-9]+/g, '-');
            const candidates = htmlFiles.filter(h => 
                h.slug.toLowerCase().includes(subjectSlug.substring(0, 5)) &&
                h.slug.includes(`Semester ${meta.semester}`)
            );
            
            // If only one candidate in same subject, use it
            if (candidates.length === 1) {
                matched = candidates[0];
            }
        }
        
        if (matched) {
            mapping[docId] = matched.absolutePath;
        } else {
            unmatched.push({ docId, source: meta.source });
        }
    }
    
    return { mapping, unmatched };
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
 * Rewrite internal links in HTML
 */
function rewriteLinks(html, routeToDocId) {
    const dom = new JSDOM(html);
    const doc = dom.window.document;
    
    const anchors = doc.querySelectorAll('a[href]');
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
        let targetPath = href;
        if (href.startsWith('/docs/')) {
            targetPath = href.replace(/\/$/, ''); // Remove trailing slash
        }
        
        // Look up docId
        const docId = routeToDocId.get(targetPath) || 
                      routeToDocId.get(targetPath.toLowerCase()) ||
                      routeToDocId.get(decodeURIComponent(targetPath));
        
        if (docId) {
            const fragment = href.includes('#') ? href.substring(href.indexOf('#')) : '';
            anchor.setAttribute('href', `app://doc/${docId}${fragment}`);
        }
    }
    
    return dom.serialize();
}

/**
 * Main export function - alternative approach
 * Instead of matching source to build, just export all HTML from build
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
    
    // Export all HTML files with a generated docId based on path
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
            
            // Skip if empty
            if (!docId) {
                docId = 'root';
            }
            
            // Read and process HTML
            let html = fs.readFileSync(htmlFile.absolutePath, 'utf-8');
            html = rewriteLinks(html, routeToDocId);
            
            // Write output
            const outputPath = path.join(CONTENT_DOCS_DIR, `${docId}.html`);
            fs.writeFileSync(outputPath, html, 'utf-8');
            
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
    
    // Update registry to match exported docs
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
    
    // Write updated registry
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
