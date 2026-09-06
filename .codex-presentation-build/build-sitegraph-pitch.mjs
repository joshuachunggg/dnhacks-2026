import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { Presentation, PresentationFile } from "@oai/artifact-tool";

const workspaceDir = "/Users/joshuachung/Documents/Projects/dnhacks-2026";
const skillDir = "/Users/joshuachung/.codex/plugins/cache/openai-primary-runtime/presentations/26.904.11930/skills/presentations";
const buildDir = path.join(workspaceDir, ".codex-presentation-build");
const finalPath = path.join(workspaceDir, "deliverables", "sitegraph-hackathon-pitch.pptx");
const candidatePath = path.join(workspaceDir, ".codex-finalizer", "sitegraph-hackathon-pitch-candidate.pptx");
const { resolvePresentationFont, finalizePresentation } = await import(pathToFileURL(
  path.join(skillDir, "container_tools", "artifact_tool_utils.mjs"),
).href);
const font = resolvePresentationFont();
const C = { navy: "#183B56", ink: "#17212B", blue: "#28678A", sky: "#DDF2FB", mist: "#F4F8FA", pale: "#EAF5F9", green: "#6F928B", white: "#FFFFFF", line: "#B9D4DE", amber: "#F2C46D" };
const deck = Presentation.create({ slideSize: { width: 1280, height: 720 } });

function box(slide, text, left, top, width, height, options = {}) {
  const shape = slide.shapes.add({ geometry: "textbox", position: { left, top, width, height }, fill: "none", line: { fill: "none", width: 0 } });
  shape.text = text;
  shape.text.style = { typeface: font, fontSize: options.size ?? 22, bold: options.bold ?? false, color: options.color ?? C.ink, autoFit: "shrinkText", ...(options.align ? { align: options.align } : {}) };
  return shape;
}
function rect(slide, left, top, width, height, fill, radius = false, line = "none") {
  return slide.shapes.add({ geometry: radius ? "roundRect" : "rect", position: { left, top, width, height }, fill, line: { fill: line, width: line === "none" ? 0 : 1 } });
}
function header(slide, n, title, subtitle) {
  rect(slide, 0, 0, 1280, 16, C.blue);
  box(slide, `0${n}`, 42, 39, 50, 26, { size: 14, bold: true, color: C.blue });
  box(slide, title, 42, 72, 920, 68, { size: 39, bold: true, color: C.navy });
  if (subtitle) box(slide, subtitle, 42, 145, 950, 42, { size: 18, color: "#49606F" });
  rect(slide, 42, 686, 1196, 1, C.line);
  box(slide, "SITEGRAPH  |  DNHACKS 2026", 42, 696, 330, 14, { size: 10, bold: true, color: C.blue });
  box(slide, String(n), 1210, 696, 28, 14, { size: 10, color: C.blue, align: "right" });
}
function label(slide, text, left, top, width, fill = C.sky, color = C.navy) {
  rect(slide, left, top, width, 26, fill, true);
  box(slide, text.toUpperCase(), left + 12, top + 6, width - 24, 14, { size: 10, bold: true, color });
}
function note(slide, text) { slide.speakerNotes.textFrame.setText(text); }

// 1. Cover
{
  const s = deck.slides.add(); s.background.fill = C.white;
  rect(s, 0, 0, 1280, 18, C.blue);
  box(s, "SITEGRAPH", 48, 58, 240, 30, { size: 16, bold: true, color: C.blue });
  box(s, "A field engineer\nfor every homeowner.", 48, 122, 630, 160, { size: 54, bold: true, color: C.navy });
  box(s, "Understand the house, plan the project, and walk into every quote with evidence.", 52, 308, 500, 66, { size: 23, color: "#49606F" });
  label(s, "Starting with Level 2 EV charging", 52, 410, 292);
  // Abstract measured home plan.
  rect(s, 735, 86, 418, 434, C.mist, true);
  rect(s, 770, 132, 350, 300, C.white, false, C.line);
  rect(s, 770, 132, 350, 5, C.blue);
  rect(s, 942, 132, 5, 300, C.line);
  rect(s, 770, 274, 350, 5, C.line);
  rect(s, 850, 274, 5, 158, C.line);
  rect(s, 770, 378, 82, 5, C.blue);
  rect(s, 1007, 274, 5, 105, C.blue);
  rect(s, 1010, 334, 48, 48, C.sky, true);
  box(s, "EVSE", 1018, 350, 34, 14, { size: 9, bold: true, color: C.navy, align: "center" });
  rect(s, 796, 177, 52, 62, C.navy, true);
  box(s, "PANEL", 802, 201, 40, 14, { size: 9, bold: true, color: C.white, align: "center" });
  box(s, "panel", 778, 246, 56, 14, { size: 10, color: C.blue });
  box(s, "garage", 965, 292, 66, 14, { size: 10, color: C.blue });
  box(s, "31 ft planned route", 864, 454, 170, 20, { size: 13, bold: true, color: C.navy, align: "center" });
  rect(s, 735, 564, 418, 1, C.line);
  box(s, "Spatial context  •  structured evidence  •  clear next steps", 755, 585, 380, 28, { size: 14, color: C.navy, align: "center" });
  rect(s, 0, 634, 1280, 86, C.navy);
  box(s, "DNHacks 2026", 48, 662, 230, 20, { size: 14, bold: true, color: C.white });
  box(s, "A more legible home changes who gets to make informed decisions.", 550, 662, 680, 20, { size: 14, color: "#DDECF1", align: "right" });
  note(s, "Opening: SiteGraph gives homeowners an evidence-based planning layer for complex home projects. Today’s demo focuses on a new Level 2 EV charger assessment.");
}

// 2. Pain / audience
{
  const s = deck.slides.add(); s.background.fill = C.white;
  header(s, 2, "The homeowner starts at an information disadvantage.", "The hardest part of a home project often arrives before any work begins.");
  const cards = [
    ["Opaque scope", "A quote can hide what the work assumes about the panel, route, service, or permit path."],
    ["Uneven expertise", "The homeowner has to evaluate technical claims without the observations that support them."],
    ["Costly uncertainty", "A vague recommendation can become an avoidable upgrade, delay, or predatory price."],
  ];
  cards.forEach(([t, b], i) => {
    const x = 42 + i * 400;
    rect(s, x, 235, 354, 222, i === 1 ? C.pale : C.mist, true);
    rect(s, x + 24, 260, 40, 40, i === 1 ? C.blue : C.green, true);
    box(s, `0${i + 1}`, x + 32, 272, 24, 14, { size: 10, bold: true, color: C.white, align: "center" });
    box(s, t, x + 24, 324, 280, 28, { size: 21, bold: true, color: C.navy });
    box(s, b, x + 24, 365, 300, 67, { size: 16, color: "#405564" });
  });
  label(s, "Who we serve", 42, 518, 132, C.navy, C.white);
  box(s, "Homeowners planning a high-stakes upgrade who need enough clarity to ask better questions, compare scope, and know when a licensed professional must decide.", 42, 556, 1100, 52, { size: 22, color: C.navy });
  note(s, "Pain point: residential projects are opaque precisely when stakes are high. We serve homeowners, especially those planning upgrades without technical training. We do not replace licensed professionals.");
}

// 3. Current product
{
  const s = deck.slides.add(); s.background.fill = C.white;
  header(s, 3, "Today, SiteGraph turns a room into a defensible starting point.", "A guided capture flow creates a shared record before anyone starts guessing.");
  const steps = [
    ["Capture", "Scan one room and collect panel, route, and proposed-location context."],
    ["Structure", "Label what was observed, supplied, or estimated. Keep confidence and evidence visible."],
    ["Calculate", "Run deterministic feasibility and planning-cost tools against the structured assessment."],
    ["Handoff", "Show assumptions, unresolved checks, and the questions for an electrician or installer."],
  ];
  steps.forEach(([t, b], i) => {
    const x = 42 + i * 300;
    rect(s, x, 250, 252, 252, i === 2 ? C.navy : C.mist, true);
    box(s, `0${i + 1}`, x + 24, 276, 46, 28, { size: 15, bold: true, color: i === 2 ? C.amber : C.blue });
    box(s, t, x + 24, 329, 204, 28, { size: 22, bold: true, color: i === 2 ? C.white : C.navy });
    box(s, b, x + 24, 376, 204, 83, { size: 15, color: i === 2 ? "#DDECF1" : "#405564" });
  });
  rect(s, 294, 368, 48, 4, C.blue, true); rect(s, 594, 368, 48, 4, C.blue, true); rect(s, 894, 368, 48, 4, C.blue, true);
  label(s, "Current demo boundary", 42, 552, 212, C.sky);
  box(s, "Level 2 EV charger planning with seeded or captured evidence, preliminary ranges, explicit provenance, and professional-verification items. No quote, certification, or permit approval claim.", 42, 590, 1120, 45, { size: 18, color: C.navy });
  note(s, "Current capability: RoomPlan-backed spatial context, typed evidence, deterministic engineering and cost scenarios, and installer handoff. The displayed range is preliminary and fixture-scoped, never a contractor quote.");
}

// 4. Technical proof
{
  const s = deck.slides.add(); s.background.fill = C.white;
  header(s, 4, "AI guides the work. Deterministic tools defend the answer.", "SiteGraph couples a real-time field assistant with typed evidence and calculations that fail closed when facts are missing.");
  const layers = [
    ["01  Spatial capture", "Native RoomPlan scan, local USDZ artifact, and a SHA-256 descriptor preserve a concrete spatial record."],
    ["02  Real-time guide", "A server-minted Realtime session gathers structured facts, requests only supported evidence, and follows a bounded policy."],
    ["03  Typed boundary", "Zod-validated SiteGraph events label observations, user inputs, spatial facts, confidence, and evidence IDs."],
    ["04  Deterministic output", "Engineering and cost services return assumptions, warnings, provenance, and insufficient-data states instead of invented certainty."],
  ];
  layers.forEach(([t, b], i) => {
    const y = 226 + i * 91;
    rect(s, 42, y, 1158, 70, i % 2 ? C.mist : C.pale, true);
    box(s, t, 66, y + 17, 268, 25, { size: 17, bold: true, color: C.navy });
    box(s, b, 360, y + 14, 806, 39, { size: 15, color: "#405564" });
  });
  label(s, "Why this matters", 42, 604, 160, C.navy, C.white);
  box(s, "The model makes capture conversational. The system makes results auditable. That is what lets AI participate in a high-trust home decision without becoming the final authority.", 222, 608, 974, 35, { size: 17, bold: true, color: C.navy });
  note(s, "Technical proof for judges: native RoomPlan capture and USDZ backup, direct Realtime PCM transport with server-minted ephemeral secrets, bounded consumer-capability policy, Zod-validated SiteGraph events, evidence registry, deterministic engineering and cost contracts, explicit insufficient_data and partial-range states, and regression checks. This directly addresses technical sophistication and reliability in the official DNHacks rubric: https://portal.dnhacks.org/e/2026/judging");
}

// 5. Future
{
  const s = deck.slides.add(); s.background.fill = C.white;
  header(s, 5, "The EV charger is the wedge. The home is the platform.", "The same evidence layer can make more of the home understandable before a purchase or proposal.");
  const phases = [
    ["Now", "EV charger\nplanning", "Capture spatial context, model a route, and surface a transparent planning range."],
    ["Next", "Quote-ready\ncomparisons", "Normalize scope, assumptions, exclusions, and questions across contractor proposals."],
    ["Then", "Home project\nintelligence", "Apply the same record to electrification, remodels, additions, and adjacent-room changes."],
  ];
  phases.forEach(([phase, title, copy], i) => {
    const x = 42 + i * 408;
    rect(s, x, 245, 366, 290, i === 0 ? C.navy : C.mist, true);
    label(s, phase, x + 24, 271, 78, i === 0 ? C.amber : C.sky, C.navy);
    box(s, title, x + 24, 324, 290, 62, { size: 28, bold: true, color: i === 0 ? C.white : C.navy });
    box(s, copy, x + 24, 411, 300, 82, { size: 16, color: i === 0 ? "#DDECF1" : "#405564" });
  });
  rect(s, 370, 387, 48, 4, C.blue, true); rect(s, 778, 387, 48, 4, C.blue, true);
  box(s, "The goal: make each project more legible before homeowners commit time or money.", 42, 586, 1090, 40, { size: 23, bold: true, color: C.navy });
  note(s, "Future: quote comparison and broader home-project intelligence are product directions, not current features. The demonstrated foundation is structured evidence and explicit uncertainty.");
}

// 6. Ethos
{
  const s = deck.slides.add(); s.background.fill = C.white;
  header(s, 6, "Our product ethic: clarity without false certainty.", "SiteGraph should make the homeowner more capable while keeping professional boundaries clear.");
  const values = [
    ["Evidence over theater", "Every recommendation carries its inputs, source, assumptions, and unresolved checks."],
    ["Education without upsell", "We explain the project in plain language so homeowners can compare options on their terms."],
    ["Respect the boundary", "We surface the questions. Licensed professionals make the decisions that require them."],
  ];
  values.forEach(([t, b], i) => {
    const y = 238 + i * 126;
    rect(s, 42, y, 92, 92, i === 1 ? C.blue : C.green, true);
    box(s, String(i + 1), 42, y + 25, 92, 32, { size: 24, bold: true, color: C.white, align: "center" });
    box(s, t, 172, y + 5, 400, 28, { size: 23, bold: true, color: C.navy });
    box(s, b, 172, y + 43, 620, 48, { size: 17, color: "#405564" });
    rect(s, 818, y + 18, 386, 58, i === 1 ? C.pale : C.mist, true);
    box(s, i === 0 ? "“Show me why.”" : i === 1 ? "“Help me compare.”" : "“Tell me what I still need.”", 842, y + 35, 338, 22, { size: 17, bold: true, color: C.navy, align: "center" });
  });
  note(s, "Ethos: democratize access to difficult home information, but do it honestly. Provenance, scope boundaries, and professional checks are product features, not disclaimers added at the end.");
}

// 7. Closing
{
  const s = deck.slides.add(); s.background.fill = C.navy;
  box(s, "SITEGRAPH", 52, 52, 200, 26, { size: 16, bold: true, color: C.amber });
  box(s, "Every homeowner deserves\na clear view of the project\ninside their walls.", 52, 133, 660, 210, { size: 49, bold: true, color: C.white });
  box(s, "We are building the planning layer that makes hard home decisions easier to understand, safer to question, and harder to price unfairly.", 56, 390, 580, 82, { size: 22, color: "#DDECF1" });
  label(s, "DNHacks 2026", 56, 520, 130, C.amber, C.navy);
  box(s, "Thank you", 56, 574, 250, 42, { size: 29, bold: true, color: C.white });
  // Architectural mark.
  rect(s, 795, 136, 334, 334, "#204B69", true);
  rect(s, 837, 201, 250, 205, C.navy, false, "#7DA6BB");
  rect(s, 837, 201, 250, 5, C.amber);
  rect(s, 960, 201, 5, 205, "#7DA6BB");
  rect(s, 837, 302, 250, 5, "#7DA6BB");
  rect(s, 888, 307, 5, 99, "#7DA6BB");
  rect(s, 1005, 307, 5, 99, C.amber);
  rect(s, 865, 238, 48, 48, C.amber, true);
  box(s, "?", 865, 247, 48, 22, { size: 20, bold: true, color: C.navy, align: "center" });
  rect(s, 1018, 332, 45, 45, C.sky, true);
  box(s, "EV", 1025, 347, 32, 14, { size: 10, bold: true, color: C.navy, align: "center" });
  box(s, "A question becomes a plan.", 830, 513, 290, 24, { size: 17, bold: true, color: C.amber, align: "center" });
  rect(s, 0, 686, 1280, 2, "#335F79");
  box(s, "sitegraph  |  spatial evidence for better home decisions", 52, 696, 670, 14, { size: 10, color: "#AFC9D5" });
  note(s, "Close: SiteGraph helps homeowners go from a question to a transparent plan. We start with EV charging and build toward a more legible home.");
}

await fs.mkdir(buildDir, { recursive: true });
await fs.mkdir(path.dirname(candidatePath), { recursive: true });
await fs.mkdir(path.dirname(finalPath), { recursive: true });
await (await PresentationFile.exportPptx(deck)).save(candidatePath);

const requirements = { explicitTotalSlideCount: 7, requiredNativeTableOwnerSlides: [], requiredNativeChartOwnerSlides: [] };
const result = await finalizePresentation({
  ...requirements,
  workspaceDir,
  candidatePath,
  finalPath,
  pythonExecutable: "/Users/joshuachung/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3",
  integrityValidatorPath: path.join(skillDir, "container_tools", "inspect_presentation_package_integrity.py"),
  layoutValidatorPath: path.join(skillDir, "container_tools", "inspect_presentation_layout_geometry.py"),
  layoutArgs: ["--expected-slide-size-emu", "12192000,6858000", "--validate-bullet-geometry", "--validate-heading-fit"],
  fontPolicy: { basis: "design", families: [font] },
  verifyArtifactToolImport: true,
  receiptPath: path.join(workspaceDir, ".codex-finalizer", "sitegraph-hackathon-pitch.validation.json"),
});
console.log(JSON.stringify({ font, finalPath, result }, null, 2));
