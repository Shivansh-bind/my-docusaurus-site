/**
 * generate_hubs.js
 * 
 * Auto-generates hub HTML pages for subjects and notes sections.
 * Hub pages contain cards linking to child content using app://doc/ links.
 * 
 * Usage: node generate_hubs.js
 */

const fs = require('fs');
const path = require('path');

// Paths
const CONTENT_DIR = path.resolve(__dirname, '..', 'content');
const DOCS_DIR = path.join(CONTENT_DIR, 'docs');
const REGISTRY_PATH = path.join(__dirname, 'doc_registry.json');

/**
 * Hub page CSS styles
 */
const HUB_STYLES = `
<style>
* { box-sizing: border-box; margin: 0; padding: 0; }
body { 
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh;
    padding: 20px;
    color: #fff;
}
.hub-container {
    max-width: 600px;
    margin: 0 auto;
}
.hub-header {
    text-align: center;
    padding: 30px 20px;
    margin-bottom: 24px;
}
.hub-icon {
    font-size: 3em;
    margin-bottom: 12px;
}
.hub-title {
    font-size: 1.8em;
    font-weight: 700;
    margin-bottom: 8px;
}
.hub-subtitle {
    font-size: 1em;
    opacity: 0.9;
}
.hub-cards {
    display: flex;
    flex-direction: column;
    gap: 16px;
}
.hub-card {
    display: flex;
    align-items: center;
    gap: 16px;
    background: rgba(255,255,255,0.95);
    color: #1a1a1a;
    padding: 20px 24px;
    border-radius: 16px;
    text-decoration: none;
    box-shadow: 0 4px 15px rgba(0,0,0,0.1);
    transition: all 0.2s ease;
}
.hub-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(0,0,0,0.15);
}
.hub-card:active {
    transform: translateY(0);
}
.card-icon {
    font-size: 2em;
    width: 50px;
    height: 50px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 12px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}
.card-content {
    flex: 1;
}
.card-title {
    font-size: 1.1em;
    font-weight: 600;
    margin-bottom: 4px;
}
.card-desc {
    font-size: 0.85em;
    color: #666;
}
.card-arrow {
    font-size: 1.2em;
    color: #999;
}
.back-link {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    color: rgba(255,255,255,0.9);
    text-decoration: none;
    margin-bottom: 16px;
    font-size: 0.95em;
}
</style>
`;

/**
 * Icon mapping for categories
 */
const CATEGORY_ICONS = {
    handout: '📘',
    notes: '📝',
    notesIndex: '📝',
    assignments: '✏️',
    misc: '🎯',
    pyq: '📋',
    projects: '🚀',
    unit: '📖',
    subjectIndex: '📚',
    semesterIndex: '🎓',
    content: '📄'
};

/**
 * Description mapping for categories
 */
const CATEGORY_DESCRIPTIONS = {
    handout: 'Official course handout and guidelines',
    notes: 'Lecture notes and study materials',
    notesIndex: 'All unit notes and materials',
    assignments: 'Homework and assignment problems',
    misc: 'Projects, quizzes, and activities',
    pyq: 'Previous year questions',
    projects: 'Project guides and resources',
    unit: 'Unit content',
    content: 'Course content'
};

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
 * Generate a subject hub page
 */
function generateSubjectHub(subjectDocId, subjectName, semester, childDocs) {
    const icon = '📚';
    const cards = childDocs
        .filter(doc => !doc.isHub || doc.category === 'notesIndex') // Include notes hub but not subject hub itself
        .sort((a, b) => a.order - b.order)
        .map(doc => {
            const cardIcon = CATEGORY_ICONS[doc.category] || '📄';
            const cardDesc = CATEGORY_DESCRIPTIONS[doc.category] || '';
            return `
    <a href="app://doc/${doc.docId}" class="hub-card">
        <div class="card-icon">${cardIcon}</div>
        <div class="card-content">
            <div class="card-title">${doc.title}</div>
            <div class="card-desc">${cardDesc}</div>
        </div>
        <div class="card-arrow">→</div>
    </a>`;
        }).join('\n');

    return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${subjectName}</title>
${HUB_STYLES}
</head>
<body>
<div class="hub-container">
    <div class="hub-header">
        <div class="hub-icon">${icon}</div>
        <h1 class="hub-title">${subjectName}</h1>
        <p class="hub-subtitle">Semester ${semester}</p>
    </div>
    <div class="hub-cards">
${cards}
    </div>
</div>
</body>
</html>`;
}

/**
 * Generate a notes hub page (lists all units)
 */
function generateNotesHub(notesDocId, subjectName, semester, unitDocs, parentHubId) {
    const icon = '📝';
    const cards = unitDocs
        .sort((a, b) => (a.unit || 0) - (b.unit || 0))
        .map(doc => {
            return `
    <a href="app://doc/${doc.docId}" class="hub-card">
        <div class="card-icon">📖</div>
        <div class="card-content">
            <div class="card-title">${doc.title}</div>
            <div class="card-desc">Study notes and materials</div>
        </div>
        <div class="card-arrow">→</div>
    </a>`;
        }).join('\n');

    const backLink = parentHubId 
        ? `<a href="app://doc/${parentHubId}" class="back-link">← Back to ${subjectName}</a>`
        : '';

    return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Notes - ${subjectName}</title>
${HUB_STYLES}
</head>
<body>
<div class="hub-container">
    ${backLink}
    <div class="hub-header">
        <div class="hub-icon">${icon}</div>
        <h1 class="hub-title">Notes</h1>
        <p class="hub-subtitle">${subjectName} • Semester ${semester}</p>
    </div>
    <div class="hub-cards">
${cards}
    </div>
</div>
</body>
</html>`;
}

/**
 * Generate a semester hub page
 */
function generateSemesterHub(semester, subjects) {
    const icon = '🎓';
    const cards = subjects
        .map(subj => {
            return `
    <a href="app://doc/${subj.hubDocId}" class="hub-card">
        <div class="card-icon">📚</div>
        <div class="card-content">
            <div class="card-title">${subj.name}</div>
            <div class="card-desc">Course materials</div>
        </div>
        <div class="card-arrow">→</div>
    </a>`;
        }).join('\n');

    return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Semester ${semester}</title>
${HUB_STYLES}
</head>
<body>
<div class="hub-container">
    <div class="hub-header">
        <div class="hub-icon">${icon}</div>
        <h1 class="hub-title">Semester ${semester}</h1>
        <p class="hub-subtitle">Course materials</p>
    </div>
    <div class="hub-cards">
${cards}
    </div>
</div>
</body>
</html>`;
}

/**
 * Main hub generation function
 */
function generateHubs() {
    console.log('🚀 Generating hub pages...');
    
    const registry = loadRegistry();
    const docs = Object.entries(registry).map(([docId, meta]) => ({ docId, ...meta }));
    
    // Ensure output directory exists
    if (!fs.existsSync(DOCS_DIR)) {
        fs.mkdirSync(DOCS_DIR, { recursive: true });
    }
    
    // Group docs by semester and subject
    const semesters = {};
    
    for (const doc of docs) {
        if (!doc.semester || doc.semester === 0) continue;
        
        if (!semesters[doc.semester]) {
            semesters[doc.semester] = {};
        }
        
        if (!doc.subject || doc.subject === 'General') continue;
        
        if (!semesters[doc.semester][doc.subject]) {
            semesters[doc.semester][doc.subject] = [];
        }
        
        semesters[doc.semester][doc.subject].push(doc);
    }
    
    let hubCount = 0;
    const generatedHubs = {};
    
    // Generate hubs for each subject
    for (const [semester, subjects] of Object.entries(semesters)) {
        const semSubjects = [];
        
        for (const [subjectName, subjectDocs] of Object.entries(subjects)) {
            // Generate subject hub ID
            const subjectSlug = subjectName.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '');
            const subjectHubId = `s${semester}_${subjectSlug}_hub`;
            
            // Find child docs for subject hub (handout, notes, assignments, misc - but not units)
            const subjectChildren = subjectDocs.filter(d => 
                ['handout', 'notesIndex', 'assignments', 'misc', 'pyq', 'projects'].includes(d.category)
            );
            
            // Also include notes hub link if there are units
            const unitDocs = subjectDocs.filter(d => d.category === 'unit');
            const notesHubId = `s${semester}_${subjectSlug}_notes_hub`;
            
            if (unitDocs.length > 0) {
                // Check if we already have a notesIndex doc
                const existingNotesIndex = subjectChildren.find(d => d.category === 'notesIndex');
                if (!existingNotesIndex) {
                    subjectChildren.push({
                        docId: notesHubId,
                        title: 'Notes',
                        category: 'notesIndex',
                        order: 2,
                        isHub: true
                    });
                }
                
                // Generate notes hub
                const notesHubHtml = generateNotesHub(notesHubId, subjectName, semester, unitDocs, subjectHubId);
                const notesHubPath = path.join(DOCS_DIR, `${notesHubId}.html`);
                fs.writeFileSync(notesHubPath, notesHubHtml, 'utf-8');
                console.log(`✅ Generated notes hub: ${notesHubId}`);
                hubCount++;
                
                generatedHubs[notesHubId] = {
                    title: `Notes - ${subjectName}`,
                    semester: parseInt(semester),
                    subject: subjectName,
                    category: 'notesHub',
                    isHub: true,
                    isGenerated: true
                };
            }
            
            // Generate subject hub
            if (subjectChildren.length > 0) {
                const subjectHubHtml = generateSubjectHub(subjectHubId, subjectName, semester, subjectChildren);
                const subjectHubPath = path.join(DOCS_DIR, `${subjectHubId}.html`);
                fs.writeFileSync(subjectHubPath, subjectHubHtml, 'utf-8');
                console.log(`✅ Generated subject hub: ${subjectHubId}`);
                hubCount++;
                
                generatedHubs[subjectHubId] = {
                    title: subjectName,
                    semester: parseInt(semester),
                    subject: subjectName,
                    category: 'subjectHub',
                    isHub: true,
                    isGenerated: true
                };
                
                semSubjects.push({
                    name: subjectName,
                    hubDocId: subjectHubId
                });
            }
        }
        
        // Generate semester hub
        if (semSubjects.length > 0) {
            const semesterHubId = `s${semester}_hub`;
            const semesterHubHtml = generateSemesterHub(semester, semSubjects);
            const semesterHubPath = path.join(DOCS_DIR, `${semesterHubId}.html`);
            fs.writeFileSync(semesterHubPath, semesterHubHtml, 'utf-8');
            console.log(`✅ Generated semester hub: ${semesterHubId}`);
            hubCount++;
            
            generatedHubs[semesterHubId] = {
                title: `Semester ${semester}`,
                semester: parseInt(semester),
                subject: 'General',
                category: 'semesterHub',
                isHub: true,
                isGenerated: true
            };
        }
    }
    
    // Merge generated hubs into registry
    const updatedRegistry = { ...registry, ...generatedHubs };
    fs.writeFileSync(REGISTRY_PATH, JSON.stringify(updatedRegistry, null, 4), 'utf-8');
    
    console.log(`\n📊 Hub Generation Summary:`);
    console.log(`   ✅ Generated: ${hubCount} hub pages`);
    console.log(`   📄 Registry: ${Object.keys(updatedRegistry).length} total entries`);
    
    return { hubCount, generatedHubs };
}

// Run if called directly
if (require.main === module) {
    generateHubs();
}

module.exports = { generateHubs };
