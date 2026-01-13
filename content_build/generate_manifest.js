/**
 * generate_manifest.js
 * 
 * Generates the content/index.json manifest from doc_registry.json.
 * This manifest includes pack version, docs lookup, and navigation tree.
 * 
 * Usage: node generate_manifest.js
 * Prerequisites: doc_registry.json must exist
 */

const fs = require('fs');
const path = require('path');

// Paths
const REPO_ROOT = path.resolve(__dirname, '..');
const CONTENT_DIR = path.join(REPO_ROOT, 'content');
const REGISTRY_PATH = path.join(__dirname, 'doc_registry.json');
const MANIFEST_PATH = path.join(CONTENT_DIR, 'index.json');

/**
 * Generate pack version from current date
 */
function generatePackVersion() {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    return `${year}.${month}.${day}`;
}

/**
 * Generate a slug-safe ID from a string
 */
function slugify(str) {
    return str
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '_')
        .replace(/^_|_$/g, '');
}

/**
 * Build the navigation tree from registry entries
 */
function buildTree(registry) {
    // Group by semester, then by subject
    const semesters = {};

    for (const [docId, meta] of Object.entries(registry)) {
        const sem = meta.semester;
        const subject = meta.subject;

        if (!semesters[sem]) {
            semesters[sem] = {};
        }
        if (!semesters[sem][subject]) {
            semesters[sem][subject] = [];
        }

        semesters[sem][subject].push({
            docId,
            title: meta.title,
            type: meta.type,
            order: meta.order
        });
    }

    // Build tree structure
    const tree = [];

    // Sort semesters
    const sortedSemesters = Object.keys(semesters)
        .map(Number)
        .sort((a, b) => a - b);

    for (const sem of sortedSemesters) {
        const semesterNode = {
            id: sem === 0 ? 'intro' : `semester_${sem}`,
            title: sem === 0 ? 'Introduction' : `Semester ${sem}`,
            items: []
        };

        // Sort subjects alphabetically
        const subjects = Object.keys(semesters[sem]).sort();

        for (const subject of subjects) {
            const docs = semesters[sem][subject];

            // Sort docs by order
            docs.sort((a, b) => a.order - b.order);

            const subjectNode = {
                id: `subject_s${sem}_${slugify(subject)}`,
                title: subject,
                items: docs.map(doc => ({
                    docId: doc.docId,
                    title: doc.title,
                    type: doc.type
                }))
            };

            semesterNode.items.push(subjectNode);
        }

        tree.push(semesterNode);
    }

    return tree;
}

/**
 * Build the docs lookup map
 */
function buildDocsMap(registry) {
    const docs = {};

    for (const [docId, meta] of Object.entries(registry)) {
        docs[docId] = {
            title: meta.title,
            semester: meta.semester,
            subject: meta.subject,
            type: meta.type,
            order: meta.order,
            html: `docs/${docId}.html`
        };
    }

    return docs;
}

/**
 * Generate the manifest
 */
function generateManifest() {
    console.log('🚀 Generating manifest...');

    // Check prerequisites
    if (!fs.existsSync(REGISTRY_PATH)) {
        throw new Error(`doc_registry.json not found at ${REGISTRY_PATH}`);
    }

    // Ensure output directory exists
    if (!fs.existsSync(CONTENT_DIR)) {
        fs.mkdirSync(CONTENT_DIR, { recursive: true });
    }

    // Load registry
    const registry = JSON.parse(fs.readFileSync(REGISTRY_PATH, 'utf-8'));
    console.log(`📚 Loaded ${Object.keys(registry).length} docs from registry`);

    // Build manifest
    const manifest = {
        packVersion: generatePackVersion(),
        generatedAt: new Date().toISOString(),
        docs: buildDocsMap(registry),
        tree: buildTree(registry)
    };

    // Write manifest
    fs.writeFileSync(MANIFEST_PATH, JSON.stringify(manifest, null, 2), 'utf-8');
    console.log(`✅ Manifest written to ${MANIFEST_PATH}`);
    console.log(`   📦 Pack version: ${manifest.packVersion}`);
    console.log(`   📄 Docs count: ${Object.keys(manifest.docs).length}`);
    console.log(`   🌳 Tree nodes: ${manifest.tree.length} semesters`);

    return manifest;
}

// Run if called directly
if (require.main === module) {
    try {
        generateManifest();
    } catch (err) {
        console.error('Fatal error:', err);
        process.exit(1);
    }
}

module.exports = { generateManifest, buildTree, buildDocsMap };
