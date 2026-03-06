import { describe, expect, it } from "vitest";
import { __test } from "./index.js";

describe("desktop-apprentice learning", () => {
  it("tracks transition counts and sorts prediction confidence", () => {
    const graph: Record<string, Record<string, number>> = {};

    __test.incrementTransition(graph, "Finder", "Terminal");
    __test.incrementTransition(graph, "Finder", "Terminal");
    __test.incrementTransition(graph, "Finder", "Chrome");

    const predictions = __test.sortedPredictions(graph, "Finder");
    expect(predictions).toHaveLength(2);
    expect(predictions[0]?.toApp).toBe("Terminal");
    expect(predictions[0]?.count).toBe(2);
    expect(predictions[0]?.confidence).toBeCloseTo(2 / 3, 5);
    expect(predictions[1]?.toApp).toBe("Chrome");
    expect(predictions[1]?.confidence).toBeCloseTo(1 / 3, 5);
  });

  it("builds a student plan with confidence and loop guards", () => {
    const graph: Record<string, Record<string, number>> = {
      Finder: { Terminal: 8, Chrome: 2 },
      Terminal: { Notes: 7, Finder: 3 },
      Notes: { Finder: 9 },
    };

    const plan = __test.buildStudentPlan({
      graph,
      startApp: "Finder",
      minConfidence: 0.55,
      maxSteps: 5,
    });

    expect(plan).toEqual([
      { kind: "open_app", appName: "Terminal" },
      { kind: "open_app", appName: "Notes" },
    ]);
  });
});

describe("desktop-apprentice parser", () => {
  it("parses key chord with aliases", () => {
    expect(__test.parseKeyChord("cmd+shift+p")).toEqual({
      key: "p",
      modifiers: ["command", "shift"],
    });
    expect(__test.parseKeyChord("ctrl+opt+k")).toEqual({
      key: "k",
      modifiers: ["control", "option"],
    });
  });

  it("normalizes config with clamped values", () => {
    const config = __test.normalizeConfig(
      {
        pollIntervalMs: 20,
        maxEvents: 50_000,
        minConfidence: 8,
        proposalCooldownMs: -1,
        studentMaxSteps: 0,
        knowledgeFile: "./my-kb.json",
      },
      (input: string) => `/workspace/${input}`,
    );

    expect(config.pollIntervalMs).toBe(1_000);
    expect(config.maxEvents).toBe(20_000);
    expect(config.minConfidence).toBe(1);
    expect(config.proposalCooldownMs).toBe(0);
    expect(config.studentMaxSteps).toBe(1);
    expect(config.knowledgeFile).toBe("/workspace/./my-kb.json");
  });
});
