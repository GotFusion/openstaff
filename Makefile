SHELL := /bin/zsh
APP_PACKAGE_PATH := apps/macos
APP_TARGET := OpenStaffApp
CAPTURE_TARGET := OpenStaffCaptureCLI
SLICE_TARGET := OpenStaffTaskSlicerCLI
KNOWLEDGE_TARGET := OpenStaffKnowledgeBuilderCLI
ARGS ?=

.PHONY: build dev capture slice knowledge llm-prompts llm-validate llm-call llm-retry-demo

build:
	swift build --package-path $(APP_PACKAGE_PATH)

dev:
	swift run --package-path $(APP_PACKAGE_PATH) $(APP_TARGET)

capture:
	swift run --package-path $(APP_PACKAGE_PATH) $(CAPTURE_TARGET) $(ARGS)

slice:
	swift run --package-path $(APP_PACKAGE_PATH) $(SLICE_TARGET) $(ARGS)

knowledge:
	swift run --package-path $(APP_PACKAGE_PATH) $(KNOWLEDGE_TARGET) $(ARGS)

llm-prompts:
	python3 scripts/llm/render_knowledge_prompts.py --knowledge-item core/knowledge/examples/knowledge-item.sample.json --out-dir /tmp/openstaff-llm-prompts

llm-validate:
	python3 scripts/llm/validate_knowledge_parse_output.py --input scripts/llm/examples/knowledge-parse-output.sample.json --knowledge-item core/knowledge/examples/knowledge-item.sample.json

llm-call:
	python3 scripts/llm/chatgpt_adapter.py --provider text --knowledge-item core/knowledge/examples/knowledge-item.sample.json --output /tmp/openstaff-llm-call-output.json $(ARGS)

llm-retry-demo:
	python3 scripts/llm/chatgpt_adapter.py --provider text --knowledge-item core/knowledge/examples/knowledge-item.sample.json --simulate-transient-failures 2 --max-retries 3 --output /tmp/openstaff-llm-retry-demo-output.json $(ARGS)
