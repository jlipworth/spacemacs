export const meta = {
  name: 'layer-audit',
  description: 'Audit enabled Spacemacs layers for gaps/staleness/improvements; emit structured findings',
  whenToUse: 'Assess which Spacemacs layers are underbuilt vs mature and produce an actionable, evidence-backed hitlist',
  phases: [
    { title: 'Audit', detail: 'one agent per layer: read code, diff upstream, research ecosystem' },
    { title: 'Verify', detail: 'skeptic re-checks each finding against the real code' },
    { title: 'Scout', detail: 'propose high-value layers the user does not enable yet' },
  ],
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const REPO = '/Users/jlipworth/.emacs.d'
const DOTSPACEMACS = '/Users/jlipworth/GNU_files/.spacemacs'
const UPSTREAM = 'syl20bnr/develop'
const GOLD = 'layers/+lang/python' // in-repo maturity gold standard

// Enabled layers that live in this fork (claude-code + whisper excluded: external).
const REGISTRY = [
  { name: 'helm', path: 'layers/+completion/helm' },
  { name: 'treemacs', path: 'layers/+filetree/treemacs' },
  { name: 'multiple-cursors', path: 'layers/+misc/multiple-cursors' },
  { name: 'ibuffer', path: 'layers/+emacs/ibuffer' },
  { name: 'ranger', path: 'layers/+tools/ranger' },
  { name: 'spacemacs-layouts', path: 'layers/+spacemacs/spacemacs-layouts' },
  { name: 'spell-checking', path: 'layers/+checkers/spell-checking' },
  { name: 'git', path: 'layers/+source-control/git' },
  { name: 'auto-completion', path: 'layers/+completion/auto-completion' },
  { name: 'syntax-checking', path: 'layers/+checkers/syntax-checking' },
  { name: 'lsp', path: 'layers/+tools/lsp' },
  { name: 'dap', path: 'layers/+tools/dap' },
  { name: 'org', path: 'layers/+emacs/org' },
  { name: 'markdown', path: 'layers/+lang/markdown' },
  { name: 'shell', path: 'layers/+tools/shell' },
  { name: 'emacs-lisp', path: 'layers/+lang/emacs-lisp' },
  { name: 'yaml', path: 'layers/+lang/yaml' },
  { name: 'toml', path: 'layers/+lang/toml' },
  { name: 'csv', path: 'layers/+lang/csv' },
  { name: 'shell-scripts', path: 'layers/+lang/shell-scripts' },
  { name: 'vimscript', path: 'layers/+lang/vimscript' },
  { name: 'latex', path: 'layers/+lang/latex' },
  { name: 'pdf', path: 'layers/+readers/pdf' },
  { name: 'python', path: 'layers/+lang/python' },
  { name: 'c-c++', path: 'layers/+lang/c-c++' },
  { name: 'ocaml', path: 'layers/+lang/ocaml' },
  { name: 'sql', path: 'layers/+lang/sql' },
  { name: 'ess', path: 'layers/+lang/ess' },
  { name: 'javascript', path: 'layers/+lang/javascript' },
  { name: 'typescript', path: 'layers/+lang/typescript' },
  { name: 'react', path: 'layers/+frameworks/react' },
  { name: 'html', path: 'layers/+lang/html' },
  { name: 'nginx', path: 'layers/+tools/nginx' },
  { name: 'ansible', path: 'layers/+tools/ansible' },
  { name: 'terraform', path: 'layers/+tools/terraform' },
  { name: 'rust', path: 'layers/+lang/rust' },
  { name: 'docker', path: 'layers/+tools/docker' },
  { name: 'kubernetes', path: 'layers/+tools/kubernetes' },
  { name: 'windows-scripts', path: 'layers/+lang/windows-scripts' },
]

// ---------------------------------------------------------------------------
// Schemas
// ---------------------------------------------------------------------------
const FINDING_PROPS = {
  title: { type: 'string', description: 'Short imperative finding title' },
  kind: { type: 'string', enum: ['gap', 'bug', 'modernization', 'enhancement', 'cleanup'] },
  severity: { type: 'string', enum: ['high', 'medium', 'low'] },
  effort: { type: 'string', enum: ['S', 'M', 'L'] },
  evidence: {
    type: 'array',
    description: 'Concrete proof: file:line refs, upstream-diff notes, or web sources. REQUIRED.',
    items: { type: 'string' },
  },
  detail: { type: 'string', description: 'Handoff-ready description: what, why, and a concrete approach another agent could implement.' },
  deliverable: { type: 'string', enum: ['issue', 'md', 'both'] },
}

const AUDIT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['layer', 'category', 'maturity', 'upstream_delta', 'findings'],
  properties: {
    layer: { type: 'string' },
    category: { type: 'string', description: 'lang | tool | completion | checker | etc.' },
    maturity: {
      type: 'object',
      additionalProperties: false,
      required: ['rating', 'summary'],
      properties: {
        rating: { type: 'string', enum: ['mature', 'adequate', 'underbuilt', 'broken'] },
        summary: { type: 'string', description: '1-3 sentences justifying the rating by capability coverage' },
      },
    },
    upstream_delta: { type: 'string', description: 'How the fork layer differs from upstream develop: ahead/behind/diverged/identical, with specifics.' },
    findings: {
      type: 'array',
      items: { type: 'object', additionalProperties: false, required: ['title', 'kind', 'severity', 'effort', 'evidence', 'detail', 'deliverable'], properties: FINDING_PROPS },
    },
  },
}

const VERIFIED_FINDING_PROPS = Object.assign({}, FINDING_PROPS, {
  status: { type: 'string', enum: ['confirmed', 'adjusted', 'rejected'] },
  verify_note: { type: 'string', description: 'Why confirmed/adjusted/rejected, with evidence checked.' },
})

const VERIFY_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['layer', 'maturity', 'findings', 'missed_findings'],
  properties: {
    layer: { type: 'string' },
    maturity: {
      type: 'object',
      additionalProperties: false,
      required: ['rating', 'summary'],
      properties: {
        rating: { type: 'string', enum: ['mature', 'adequate', 'underbuilt', 'broken'] },
        summary: { type: 'string' },
      },
    },
    findings: {
      type: 'array',
      description: 'Every audit finding, each annotated with a status.',
      items: { type: 'object', additionalProperties: false, required: ['title', 'kind', 'severity', 'effort', 'evidence', 'detail', 'deliverable', 'status', 'verify_note'], properties: VERIFIED_FINDING_PROPS },
    },
    missed_findings: {
      type: 'array',
      description: 'Real gaps the auditor missed (same shape as a confirmed finding).',
      items: { type: 'object', additionalProperties: false, required: ['title', 'kind', 'severity', 'effort', 'evidence', 'detail', 'deliverable'], properties: FINDING_PROPS },
    },
  },
}

const SCOUT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['suggestions'],
  properties: {
    suggestions: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['name', 'provides', 'why_relevant', 'value', 'availability'],
        properties: {
          name: { type: 'string', description: 'Layer or package name' },
          provides: { type: 'string' },
          why_relevant: { type: 'string', description: 'Why it fits THIS user given their enabled stack' },
          value: { type: 'string', enum: ['high', 'medium', 'low'] },
          availability: { type: 'string', enum: ['builtin-layer', 'upstream-only', 'external-package', 'custom-needed'] },
        },
      },
    },
  },
}

// ---------------------------------------------------------------------------
// Prompts
// ---------------------------------------------------------------------------
function auditPrompt(layer) {
  return `You are auditing the Spacemacs layer \`${layer.name}\` in a personal fork at ${REPO}.
Layer directory: ${REPO}/${layer.path}

Produce a CRITICAL, evidence-backed assessment of how this layer could be built up or improved. Be a demanding reviewer — do NOT be sycophantic. If the layer is genuinely mature, say so and report few/no findings; if it is thin, say exactly what is missing.

## Steps (do all of them)
1. Read every \`.el\` file and \`README.org\` in the layer directory. Understand what it actually provides: packages, keybindings (SPC m menu), backends, formatters, REPL/eval, debugging, tests, treesit.
2. Read the user's ACTUAL config at the absolute path ${DOTSPACEMACS} (this is the real dotfile; \`~/.spacemacs\` is only a symlink to it — do NOT search other standard paths, read this exact file). Find the \`(${layer.name} :variables ...)\` block (or the bare \`${layer.name}\` symbol). Note the choices they made, anything commented out, and unfinished intent. Evaluate gaps relative to how THEY use it. Cite line numbers from this file as evidence.
3. Diff against upstream. For each file run:
   \`git -C ${REPO} show ${UPSTREAM}:${layer.path}/<file> 2>/dev/null\`
   and compare to the fork's version. Determine if the fork is ahead / behind / diverged / identical, and whether upstream has improvements the fork lacks (or vice-versa). Capture specifics in \`upstream_delta\`.
4. Research the modern ecosystem for this language/tool using web search/fetch: newer or better packages, tree-sitter (\`*-ts-mode\`) support, current LSP servers, DAP debug adapters, formatters/linters, test runners, REPL integrations. Identify what a best-in-class layer would offer today.
5. Compare against the in-repo gold standard at ${REPO}/${GOLD} (the python layer: rich config.el/funcs.el/packages.el/layers.el plus tests under tests/layers/+lang/python/). Use it as the bar for "mature".

## Output rules
- Rate maturity by CAPABILITY COVERAGE, not line count (a small layer for a simple tool can still be mature).
- EVERY finding must include concrete \`evidence\`: a \`file:line\` reference, an upstream-diff observation, or a web source URL. No evidence => do not report it.
- \`detail\` must be handoff-ready: what to change, why, and a concrete implementation approach another engineer/agent could pick up.
- Set \`deliverable\`: \`issue\` for a discrete actionable task, \`md\` for something needing a longer write-up/roadmap, \`both\` if it warrants a roadmap section AND tracking issues.
- Do NOT write any files, create issues, or modify config. Only read and return the structured result.

Return the structured audit object.`
}

function verifyPrompt(layer, audit) {
  return `You are a skeptical verifier checking an audit of the Spacemacs layer \`${layer.name}\` (fork at ${REPO}, layer dir ${REPO}/${layer.path}).

Here is the audit to scrutinize:
${JSON.stringify(audit, null, 2)}

The user's actual config is at the absolute path ${DOTSPACEMACS} (\`~/.spacemacs\` is only a symlink to it). When a finding cites the user's config, re-read THIS exact file to confirm line numbers and \`:variables\` choices — do not dismiss a config claim as "unverifiable" without reading it here first.

For EACH finding:
- Re-check its evidence against the actual code (read the cited files; run \`git -C ${REPO} show ${UPSTREAM}:${layer.path}/<file>\` if the claim is about upstream).
- Kill false positives: if the layer ALREADY provides the thing claimed missing, mark \`status: rejected\` and say where it exists.
- If the claim is real but mis-stated (wrong severity/effort, imprecise detail), fix it and mark \`status: adjusted\`.
- If it holds up, mark \`status: confirmed\`.
Then add any genuinely important gaps the auditor MISSED to \`missed_findings\` (same evidence bar).
Re-state the maturity rating (revise if the verification changed the picture).

Be strict and concrete. Do NOT write files or create issues. Return the structured verification object.`
}

function scoutPrompt(domain, focus, enabledNames) {
  return `You advise a power user on Spacemacs layers they should ADOPT but currently do NOT enable. Focus area: ${domain} — ${focus}.

Their currently enabled layers: ${enabledNames.join(', ')}.

Available built-in layers live under ${REPO}/layers/ (browse with: ls ${REPO}/layers/*/ ). Upstream-only layers may exist in \`git -C ${REPO} ls-tree -r --name-only ${UPSTREAM} -- layers/\`. Also consider strong external packages with no layer yet.

Propose only HIGH-SIGNAL additions that fit this user's stack (heavy multi-language dev + devops + writing/org). For each: what it provides, why it's relevant to THEM specifically, value, and availability. Skip anything redundant with what they already enable. Use web search to confirm a package is current/maintained. Return the structured suggestions object.`
}

// ---------------------------------------------------------------------------
// Driver
// ---------------------------------------------------------------------------
// Normalize args: accept an array, an object {layers,scout}, a JSON string, or
// a comma/space-separated string of layer names. Falsy => audit everything.
function normalizeArgs(a) {
  if (a == null || a === '') return {}
  if (Array.isArray(a)) return { layers: a, scout: false }
  if (typeof a === 'object') return a
  if (typeof a === 'string') {
    const s = a.trim()
    try {
      const parsed = JSON.parse(s)
      return normalizeArgs(parsed)
    } catch (e) {
      const layers = s.split(/[,\s]+/).filter(Boolean)
      return { layers, scout: false }
    }
  }
  return {}
}
const requested = normalizeArgs(args)
const targetNames = requested.layers && requested.layers.length ? requested.layers : REGISTRY.map((l) => l.name)
const doScout = requested.scout !== undefined ? requested.scout : !(requested.layers && requested.layers.length)

const targets = targetNames
  .map((n) => REGISTRY.find((l) => l.name === n))
  .filter(Boolean)

log(`Auditing ${targets.length} layer(s): ${targets.map((t) => t.name).join(', ')}${doScout ? ' (+ new-layer scout)' : ''}`)

// Model for the fan-out. Override per run via args.model ('sonnet' | 'opus' |
// 'haiku') or split with args.auditModel / args.verifyModel. Omit => inherit.
const auditModel = requested.auditModel || requested.model
const verifyModel = requested.verifyModel || requested.model
const scoutModel = requested.scoutModel || requested.model

const audited = await pipeline(
  targets,
  (layer) => agent(auditPrompt(layer), { label: `audit:${layer.name}`, phase: 'Audit', schema: AUDIT_SCHEMA, ...(auditModel ? { model: auditModel } : {}) }),
  (audit, layer) => agent(verifyPrompt(layer, audit), { label: `verify:${layer.name}`, phase: 'Verify', schema: VERIFY_SCHEMA, ...(verifyModel ? { model: verifyModel } : {}) }),
)

let suggestions = []
if (doScout) {
  phase('Scout')
  const enabledNames = REGISTRY.map((l) => l.name).concat(['claude-code', 'whisper'])
  const domains = [
    ['Languages & frameworks', 'languages/frameworks worth first-class support for a polyglot dev'],
    ['DevOps & tools', 'infra, cloud, containers, data, API/HTTP, terminal tooling'],
    ['Editor UX & productivity', 'navigation, completion, search, writing/org, code intelligence'],
  ]
  const scoutResults = await parallel(
    domains.map(([d, f]) => () => agent(scoutPrompt(d, f, enabledNames), { label: `scout:${d}`, phase: 'Scout', schema: SCOUT_SCHEMA, ...(scoutModel ? { model: scoutModel } : {}) })),
  )
  suggestions = scoutResults.filter(Boolean).flatMap((r) => r.suggestions)
}

return {
  audits: audited.filter(Boolean),
  suggestions,
  audited_count: audited.filter(Boolean).length,
  requested: targetNames,
}
