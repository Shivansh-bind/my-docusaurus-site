/**
 * scan_docs.js
 * 
 * Scans the website/docs/ directory and generates a fresh doc_registry.json
 * based on actual files found. This ensures the registry matches reality.
 * 
 * Usage: node scan_docs.js
 */

const fs = require('fs');
const path = require('path');

// Paths
const REPO_ROOT = path.resolve(__dirname, '..');
const DOCS_DIR = path.join(REPO_ROOT, 'website', 'docs');
const REGISTRY_PATH = path.join(__dirname, 'doc_registry.json');

/**
 * Extract semester number from path
 */
function getSemester(relativePath) {
    const match = relativePath.match(/^Semester\s+(\d+)/i);
    if (match) return parseInt(match[1], 10);
    if (relativePath.startsWith('INTRO')) return 0;
    return 0;
}

/**
 * Extract subject from path
 */
function getSubject(relativePath, semester) {
    if (semester === 0) return 'INTRO';
    
    const parts = relativePath.split(/[/\\]/);
    if (parts.length >= 2) {
        // Clean up subject name
        return parts[1]
            .replace(/-/g, ' ')
            .replace(/\s+/g, ' ')
            .trim();
    }
    return 'Unknown';
}

/**
 * Determine content type from path and filename
 */
function getType(relativePath, filename) {
    const lowerPath = relativePath.toLowerCase();
    const lowerFile = filename.toLowerCase();
    
    if (lowerFile.includes('handout')) return 'handout';
    if (lowerPath.includes('/handout/')) return 'handout';
    if (lowerFile.includes('pyq') || lowerPath.includes('/pyq/')) return 'pyq';
    if (lowerFile.includes('assignment')) return 'assignments';
    if (lowerFile.includes('misc') || lowerFile.includes('activities')) return 'misc';
    if (lowerPath.includes('/notes/')) return 'notes';
    if (lowerFile === 'index.mdx') return 'index';
    if (lowerFile === 'intro.mdx') return 'intro';
    
    return 'notes'; // Default to notes
}

/**
 * Generate a stable docId from file path
 */
function generateDocId(relativePath, semester, subject) {
    // Normalize the path
    let normalized = relativePath
        .replace(/\.mdx$/, '')
        .replace(/[/\\]/g, '_')
        .replace(/\s+/g, '_')
        .replace(/[^a-zA-Z0-9_]/g, '')
        .toLowerCase();
    
    // Create a short prefix based on semester and subject
    const subjectKey = subject
        .replace(/\s+/g, '')
        .substring(0, 6)
        .toLowerCase();
    
    const semPrefix = semester === 0 ? 'intro' : `s${semester}`;
    
    // Get the file part
    const parts = relativePath.split(/[/\\]/);
    let fileKey = parts[parts.length - 1]
        .replace(/\.mdx$/, '')
        .replace(/\s+/g, '_')
        .replace(/[^a-zA-Z0-9_]/g, '')
        .toLowerCase();
    
    // Determine section (Handout, Notes, PYQ, etc.)
    let section = '';
    if (parts.length >= 3) {
        const folderName = parts[parts.length - 2].toLowerCase();
        if (folderName === 'notes') section = 'notes_';
        else if (folderName === 'handout') section = '';
        else if (folderName === 'pyq') section = '';
    }
    
    // Handle different cases
    if (fileKey === 'index' && parts.length >= 3) {
        const folderName = parts[parts.length - 2].toLowerCase();
        if (folderName === 'handout') {
            return `${semPrefix}_${subjectKey}_handout`;
        } else if (folderName === 'notes') {
            return `${semPrefix}_${subjectKey}_notes_index`;
        } else if (folderName === 'pyq') {
            return `${semPrefix}_${subjectKey}_pyq`;
        }
    }
    
    // For root index files
    if (fileKey === 'index' && parts.length === 2) {
        return `${semPrefix}_${subjectKey}_index`;
    }
    
    // For handout/assignments/etc files at root of subject
    if (parts.length === 2) {
        return `${semPrefix}_${subjectKey}_${fileKey}`;
    }
    
    // For notes files
    if (section === 'notes_') {
        return `${semPrefix}_${subjectKey}_notes_${fileKey}`;
    }
    
    return `${semPrefix}_${subjectKey}_${fileKey}`;
}

/**
 * Extract title from MDX frontmatter
 */
function extractTitle(filePath) {
    try {
        const content = fs.readFileSync(filePath, 'utf-8');
        const titleMatch = content.match(/^---[\s\S]*?title:\s*["']?(.+?)["']?\s*(?:\n|---)/m);
        if (titleMatch) {
            return titleMatch[1].trim().replace(/^["']|["']$/g, '');
        }
        
        // Fallback: first heading
        const headingMatch = content.match(/^#\s+(.+)$/m);
        if (headingMatch) {
            return headingMatch[1].trim();
        }
    } catch (e) {
        // Ignore
    }
    
    // Fallback to filename
    return path.basename(filePath, '.mdx').replace(/-/g, ' ');
}

/**
 * Recursively scan for MDX files
 */
function scanDocs(dir, relativeTo = dir) {
    const results = [];
    
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    
    for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);
        
        if (entry.isDirectory()) {
            results.push(...scanDocs(fullPath, relativeTo));
        } else if (entry.isFile() && entry.name.endsWith('.mdx')) {
            const relativePath = path.relative(relativeTo, fullPath).replace(/\\/g, '/');
            results.push({
                absolutePath: fullPath,
                relativePath
            });
        }
    }
    
    return results;
}

/**
 * Main function
 */
function generateRegistry() {
    console.log('🔍 Scanning docs directory...');
    
    const files = scanDocs(DOCS_DIR);
    console.log(`📄 Found ${files.length} MDX files`);
    
    const registry = {};
    const usedIds = new Set();
    
    // Sort files to ensure consistent ordering
    files.sort((a, b) => a.relativePath.localeCompare(b.relativePath));
    
    let order = 0;
    let currentSubject = '';
    
    for (const { absolutePath, relativePath } of files) {
        const semester = getSemester(relativePath);
        const subject = getSubject(relativePath, semester);
        const type = getType(relativePath, path.basename(relativePath));
        const title = extractTitle(absolutePath);
        
        // Reset order for each subject
        if (subject !== currentSubject) {
            currentSubject = subject;
            order = 0;
        }
        
        // Generate docId
        let docId = generateDocId(relativePath, semester, subject);
        
        // Handle duplicates
        let uniqueId = docId;
        let counter = 1;
        while (usedIds.has(uniqueId)) {
            uniqueId = `${docId}_${counter}`;
            counter++;
        }
        usedIds.add(uniqueId);
        
        registry[uniqueId] = {
            title,
            semester,
            subject,
            type,
            order: order++,
            source: `website/docs/${relativePath}`
        };
    }
    
    // Write registry
    fs.writeFileSync(REGISTRY_PATH, JSON.stringify(registry, null, 4), 'utf-8');
    
    console.log(`✅ Generated doc_registry.json with ${Object.keys(registry).length} entries`);
    console.log(`   📁 Output: ${REGISTRY_PATH}`);
    
    return registry;
}

// Run if called directly
if (require.main === module) {
    try {
        generateRegistry();
    } catch (err) {
        console.error('Fatal error:', err);
        process.exit(1);
    }
}

module.exports = { generateRegistry, scanDocs };
