import { AGENT_SYSTEM_PROMPT, propose } from "./agent.js";
import { USER_ALLOW, USER_INJECT } from "./constants.js";

function arg(name: string): string {
  const idx = process.argv.indexOf(`--${name}`);
  if (idx === -1 || idx + 1 >= process.argv.length) {
    throw new Error(`missing --${name}`);
  }
  return process.argv[idx + 1] ?? "";
}

function optionalArg(name: string): string | undefined {
  const idx = process.argv.indexOf(`--${name}`);
  if (idx === -1 || idx + 1 >= process.argv.length) {
    return undefined;
  }
  return process.argv[idx + 1];
}

async function main(): Promise<void> {
  const command = process.argv[2];
  if (command === "prompt") {
    console.log(AGENT_SYSTEM_PROMPT);
    return;
  }
  if (command !== "propose") {
    throw new Error("usage: agent.ts <prompt|propose> --scenario allow|inject [--mode mock|api]");
  }

  const scenario = arg("scenario");
  if (scenario !== "allow" && scenario !== "inject") {
    throw new Error("--scenario must be allow or inject");
  }
  const mode = (optionalArg("mode") ?? "mock") as "mock" | "api";
  const userMessage = scenario === "allow" ? USER_ALLOW : USER_INJECT;
  if (mode === "api") {
    const apiKey = process.env.OPENAI_API_KEY ?? "";
    if (!apiKey) {
      throw new Error("OPENAI_API_KEY is required for --mode api");
    }
    const result = await propose({
      userMessage,
      mode: "api",
      apiKey,
      model: process.env.OPENAI_MODEL ?? "gpt-4o-mini",
      baseUrl: process.env.OPENAI_BASE_URL ?? "https://api.openai.com/v1",
    });
    console.log(JSON.stringify(result));
    return;
  }
  const result = await propose({ userMessage, mode: "mock", scenario });
  console.log(JSON.stringify(result));
}

void main();
