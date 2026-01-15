/**
 * generate_manifest.js
 * 
 * Generates the index.json manifest for the content pack with:
 * - docs: all document metadata
 * - tree: navigation tree with hubDocId for parent nodes
 * - relations.nextPrev: prev/next/up for sequential docs
 * 
 * Automation Level 2: Parent nodes have hubDocId, index pages hidden from nav
 * 
 * Usage: node generate_manifest.js
 */

const fs = require('fs');
const path = require('path');

// Paths
const CONTENT_DIR = path.resolve(__dirname, '..', 'content');
const DOCS_DIR = path.join(CONTENT_DIR, 'docs');
const REGISTRY_PATH = path.join(__dirname, 'doc_registry.json');
const OUTPUT_PATH = path.join(CONTENT_DIR, 'index.json');

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
 * Build docs map from registry
 */
function buildDocsMap(registry) {
    const docs = {};
    
    for (const [docId, meta] of Object.entries(registry)) {
        docs[docId] = {
            title: meta.title || docId.replace(/_/g, ' '),
            category: meta.category || 'content',
            html: `docs/${docId}.html`,
            semester: meta.semester || 0,
            subject: meta.subject || 'General',
            unit: meta.unit || null,
            isHub: meta.isHub || false,
            order: meta.order || 0
        };
    }
    
    return docs;
}

/**
 * Build navigation tree with hubDocId for parent nodes
 * Index pages are NOT shown as leaf items
 */
function buildNavigationTree(registry) {
    const semesters = {};
    
    // Group by semester and subject
    for (const [docId, meta] of Object.entries(registry)) {
        const semester = meta.semester;
        if (!semester || semester === 0) continue;
        
        const subject = meta.subject;
        if (!subject || subject === 'General') continue;
        
        // Initialize semester
        if (!semesters[semester]) {
            semesters[semester] = {
                subjects: {}
            };
        }
        
        // Initialize subject
        if (!semesters[semester].subjects[subject]) {
            semesters[semester].subjects[subject] = {
                docs: []
            };
        }
        
        semesters[semester].subjects[subject].docs.push({
            docId,
            ...meta
        });
    }
    
    // Build tree structure
    const tree = [];
    
    for (const [semester, semData] of Object.entries(semesters).sort((a, b) => a[0] - b[0])) {
        const semSlug = `s${semester}`;
        const semHubId = `${semSlug}_hub`;
        
        const semesterNode = {
            id: semSlug,
            title: `Semester ${semester}`,
            type: 'semester',
            hubDocId: semHubId,
            items: []
        };
        
        for (const [subject, subjData] of Object.entries(semData.subjects)) {
            const subjSlug = subject.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '');
            const subjHubId = `${semSlug}_${subjSlug}_hub`;
            const notesHubId = `${semSlug}_${subjSlug}_notes_hub`;
            
            const subjectNode = {
                id: `${semSlug}_${subjSlug}`,
                title: subject,
                type: 'subject',
                hubDocId: subjHubId,
                items: []
            };
            
            // Group docs by category
            const unitDocs = subjData.docs.filter(d => d.category === 'unit').sort((a, b) => (a.unit || 0) - (b.unit || 0));
            const hasUnits = unitDocs.length > 0;
            
            // Add leaf items (NOT index pages, NOT units directly - units go through notes hub)
            const leafCategories = ['handout', 'assignments', 'misc', 'pyq', 'projects'];
            
            for (const doc of subjData.docs) {
                if (leafCategories.includes(doc.category)) {
                    subjectNode.items.push({
                        id: doc.docId,
                        title: doc.title,
                        type: 'leaf',
                        docId: doc.docId
                    });
                }
            }
            
            // Add Notes folder with units (if units exist)
            if (hasUnits) {
                const notesFolder = {
                    id: `${semSlug}_${subjSlug}_notes`,
                    title: 'Notes',
                    type: 'folder',
                    hubDocId: notesHubId,
                    items: unitDocs.map(doc => ({
                        id: doc.docId,
                        title: doc.title,
                        type: 'leaf',
                        docId: doc.docId
                    }))
                };
                subjectNode.items.unshift(notesFolder); // Notes first
            }
            
            // Sort items: Notes first, then by order
            subjectNode.items.sort((a, b) => {
                if (a.type === 'folder' && b.type !== 'folder') return -1;
                if (b.type === 'folder' && a.type !== 'folder') return 1;
                return 0;
            });
            
            if (subjectNode.items.length > 0 || hasUnits) {
                semesterNode.items.push(subjectNode);
            }
        }
        
        if (semesterNode.items.length > 0) {
            tree.push(semesterNode);
        }
    }
    
    return tree;
}

/**
 * Build relations (prev/next/up for units)
 */
function buildRelations(registry) {
    const nextPrev = {};
    const courseUnits = {};
    
    for (const [docId, meta] of Object.entries(registry)) {
        if (meta.category !== 'unit' || !meta.unit) continue;
        
        // Extract course key from docId
        const courseMatch = docId.match(/^(s\d+_[^_]+)/i);
        const course = courseMatch ? courseMatch[1] : meta.subject;
        
        if (!courseUnits[course]) {
            courseUnits[course] = [];
        }
        
        courseUnits[course].push({
            docId,
            number: meta.unit,
            semester: meta.semester,
            subject: meta.subject
        });
    }
    
    for (const [course, units] of Object.entries(courseUnits)) {
        units.sort((a, b) => a.number - b.number);
        
        // Find notes hub for this course
        const notesHub = findNotesHub(course, registry);
        
        for (let i = 0; i < units.length; i++) {
            const unit = units[i];
            nextPrev[unit.docId] = {
                prev: i > 0 ? units[i - 1].docId : null,
                next: i < units.length - 1 ? units[i + 1].docId : null,
                up: notesHub
            };
        }
    }
    
    return { nextPrev };
}

/**
 * Find notes hub for a course
 */
function findNotesHub(course, registry) {
    // Look for generated notes hub
    const notesHubId = `${course}_notes_hub`;
    if (registry[notesHubId]) {
        return notesHubId;
    }
    
    // Look for notes index
    for (const [docId, meta] of Object.entries(registry)) {
        if (docId.startsWith(course) && 
            (meta.category === 'notesIndex' || meta.category === 'notesHub')) {
            return docId;
        }
    }
    
    return null;
}

/**
 * Generate the complete manifest
 */
function generateManifest() {
    console.log('🚀 Generating manifest...');
    
    const registry = loadRegistry();
    console.log(`📚 Loaded ${Object.keys(registry).length} docs from registry`);
    
    // Build docs map
    const docs = buildDocsMap(registry);
    console.log(`📄 Built docs map with ${Object.keys(docs).length} entries`);
    
    // Build navigation tree
    const tree = buildNavigationTree(registry);
    console.log(`🌲 Built navigation tree with ${tree.length} semesters`);
    
    // Build relations
    const relations = buildRelations(registry);
    console.log(`↔️  Built relations for ${Object.keys(relations.nextPrev).length} units`);
    
    // Generate pack version from date
    const now = new Date();
    const packVersion = now.toISOString().split('T')[0].replace(/-/g, '.');
    
    // Build manifest
    const manifest = {
        packVersion,
        generatedAt: now.toISOString(),
        docs,
        tree,
        relations
    };
    
    // Validate
    validateManifest(manifest);
    
    // Write manifest
    fs.writeFileSync(OUTPUT_PATH, JSON.stringify(manifest, null, 2), 'utf-8');
    console.log(`✅ Manifest written to ${OUTPUT_PATH}`);
    
    return manifest;
}

/**
 * Validate manifest
 */
function validateManifest(manifest) {
    const errors = [];
    const docIds = new Set(Object.keys(manifest.docs));
    
    // Check tree
    function checkNode(node) {
        if (node.docId && !docIds.has(node.docId)) {
            errors.push(`tree: docId "${node.docId}" not in docs`);
        }
        if (node.hubDocId && !docIds.has(node.hubDocId)) {
            // Hub might be generated later, just warn
            console.log(`   ℹ️  Hub "${node.hubDocId}" will be generated`);
        }
        if (node.items) {
            for (const item of node.items) {
                checkNode(item);
            }
        }
    }
    for (const semester of manifest.tree) {
        checkNode(semester);
    }
    
    // Check relations
    for (const [docId, rel] of Object.entries(manifest.relations.nextPrev)) {
        if (!docIds.has(docId)) {
            errors.push(`relations: doc "${docId}" not in docs`);
        }
        if (rel.prev && !docIds.has(rel.prev)) {
            errors.push(`relations: prev "${rel.prev}" not in docs`);
        }
        if (rel.next && !docIds.has(rel.next)) {
            errors.push(`relations: next "${rel.next}" not in docs`);
        }
    }
    
    if (errors.length > 0) {
        console.warn('⚠️  Validation warnings:');
        errors.forEach(e => console.warn(`   - ${e}`));
    } else {
        console.log('✅ Manifest validation passed');
    }
}

// Run if called directly
if (require.main === module) {
    generateManifest();
}

module.exports = { generateManifest };
