// Railway helper: when LLM_API_KEY is set, add an OpenAI-compatible provider named
// "railway" to OpenCode's global config and make it the default model. The key itself
// is never written to disk: the config refers to {env:LLM_API_KEY}.
// Runs with Bun from the app folder, as the node user, before the backend starts.
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'fs'
import path from 'path'
import { applyEdits, modify, parse } from '/app/backend/node_modules/jsonc-parser'

const key = process.env.LLM_API_KEY ?? ''
if (!key) process.exit(0)
const baseURL = (process.env.LLM_BASE_URL || 'https://api.openai.com/v1').replace(/\/+$/, '')
const model = process.env.LLM_MODEL || 'gpt-4o-mini'
const dir = path.join(process.env.WORKSPACE_PATH || '/workspace', '.config', 'opencode')
mkdirSync(dir, { recursive: true })
const file = ['opencode.jsonc', 'opencode.json'].map((n) => path.join(dir, n)).find(existsSync) ?? path.join(dir, 'opencode.jsonc')
let text = existsSync(file) ? readFileSync(file, 'utf8') : '{\n  "$schema": "https://opencode.ai/config.json"\n}\n'
if (parse(text) === undefined) {
  console.error(`seed-llm: ${file} is not valid JSON, leaving it alone`)
  process.exit(0)
}
const fmt = { formattingOptions: { insertSpaces: true, tabSize: 2 } }
const set = (p: (string | number)[], v: unknown) => { text = applyEdits(text, modify(text, p, v, fmt)) }
set(['provider', 'railway'], {
  npm: '@ai-sdk/openai-compatible',
  name: 'Railway LLM (LLM_BASE_URL)',
  options: { baseURL, apiKey: '{env:LLM_API_KEY}' },
  models: { [model]: { name: model } },
})
set(['model'], `railway/${model}`)
writeFileSync(file, text)
console.log(`seed-llm: provider "railway" -> ${baseURL}, default model railway/${model} (${file})`)
