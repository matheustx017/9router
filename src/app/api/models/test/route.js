import { NextResponse } from "next/server";
import { handleChat } from "@/sse/handlers/chat.js";
import { initTranslators } from "open-sse/translator/index.js";
import { getApiKeys, getProviderConnections, updateProviderConnection } from "@/lib/localDb";
import { getModelInfo } from "@/sse/services/model.js";

let initialized = false;

async function ensureInitialized() {
  if (initialized) return;
  await initTranslators();
  initialized = true;
}

const OLLAMA_EMBED_URLS = {
  "ollama-local": "http://localhost:11434/api/embed",
};

async function tryDirectEmbedding(provider, modelName) {
  const url = OLLAMA_EMBED_URLS[provider];
  if (!url) return null;
  try {
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ model: modelName, input: "test" }),
    });
    return { ok: res.ok, status: res.status };
  } catch {
    return { ok: false, status: 502 };
  }
}

async function clearModelLock(provider, modelName) {
  const connections = await getProviderConnections({ provider });
  for (const conn of connections) {
    const lockKey = `modelLock_${modelName}`;
    if (conn[lockKey]) {
      await updateProviderConnection(conn.id, {
        [lockKey]: null,
        testStatus: "active",
        lastError: null,
        lastErrorAt: null,
        backoffLevel: 0,
      });
    }
  }
}

export async function POST(request) {
  try {
    const { model } = await request.json();
    if (!model) return NextResponse.json({ error: "Model required" }, { status: 400 });

    await ensureInitialized();

    const keys = await getApiKeys();
    const apiKey = keys.find((k) => k.isActive !== false)?.key || null;

    const headers = { "Content-Type": "application/json" };
    if (apiKey) headers.Authorization = `Bearer ${apiKey}`;

    const testRequest = new Request("http://internal/api/v1/chat/completions", {
      method: "POST",
      headers,
      body: JSON.stringify({
        model,
        messages: [{ role: "user", content: "Say OK" }],
        max_tokens: 4,
        stream: false,
      }),
    });

    const response = await handleChat(testRequest);
    const status = response.status || 200;
    const ok = status >= 200 && status < 300;

    let body;
    try {
      body = await response.json();
    } catch {
      try { body = { message: await response.text() }; } catch { body = {}; }
    }

    if (ok) {
      return NextResponse.json({ ok, status, ...body });
    }

    const errorText = String(body?.error?.message || body?.error || body?.message || "");
    if (/does not support (chat|generate)/i.test(errorText)) {
      const modelInfo = await getModelInfo(model);
      if (modelInfo.provider) {
        const embResult = await tryDirectEmbedding(modelInfo.provider, modelInfo.model);
        if (embResult?.ok) {
          await clearModelLock(modelInfo.provider, modelInfo.model);
          return NextResponse.json({ ok: true, status: 200, type: "embedding" });
        }
      }
    }

    return NextResponse.json({ ok, status, ...body }, { status: ok ? 200 : status });
  } catch (err) {
    return NextResponse.json({ ok: false, error: err.message }, { status: 500 });
  }
}
