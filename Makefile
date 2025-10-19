# Flutter PEX Project Makefile
# Local CI process for linting, formatting, and testing

.PHONY: help install clean format lint test ci all

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)Flutter PEX Project - Available Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-15s$(NC) %s\n", $$1, $$2}'

install: ## Install Flutter dependencies
	@echo "$(BLUE)Installing Flutter dependencies...$(NC)"
	flutter pub get
	@echo "$(GREEN)Dependencies installed successfully!$(NC)"

clean: ## Clean build artifacts and caches
	@echo "$(BLUE)Cleaning build artifacts...$(NC)"
	flutter clean
	flutter pub get
	@echo "$(GREEN)Clean completed!$(NC)"

format: ## Format Dart code
	@echo "$(BLUE)Formatting Dart code...$(NC)"
	dart format .
	@echo "$(GREEN)Code formatting completed!$(NC)"

format-check: ## Check if code is properly formatted (fails if changes needed)
	@echo "$(BLUE)Checking code formatting...$(NC)"
	dart format --set-exit-if-changed .
	@echo "$(GREEN)Code is properly formatted!$(NC)"

lint: ## Run Dart analyzer
	@echo "$(BLUE)Running Dart analyzer...$(NC)"
	flutter analyze
	@echo "$(GREEN)Linting completed!$(NC)"

test: ## Run Flutter tests
	@echo "$(BLUE)Running Flutter tests...$(NC)"
	flutter test --coverage
	@echo "$(GREEN)Tests completed!$(NC)"

test-verbose: ## Run Flutter tests with verbose output
	@echo "$(BLUE)Running Flutter tests with verbose output...$(NC)"
	flutter test --verbose --coverage
	@echo "$(GREEN)Verbose tests completed!$(NC)"

build-android: ## Build Android APK
	@echo "$(BLUE)Building Android APK...$(NC)"
	flutter build apk --debug
	@echo "$(GREEN)Android build completed!$(NC)"

build-ios: ## Build iOS app
	@echo "$(BLUE)Building iOS app...$(NC)"
	flutter build ios --debug --no-codesign
	@echo "$(GREEN)iOS build completed!$(NC)"

ci: format-check lint test ## Run full CI pipeline (format check + lint + test)
	@echo "$(GREEN)✅ CI pipeline completed successfully!$(NC)"

ci-fast: ## Run CI pipeline without formatting (faster)
	@echo "$(BLUE)Running fast CI pipeline (lint + test)...$(NC)"
	@$(MAKE) lint
	@$(MAKE) test
	@echo "$(GREEN)✅ Fast CI pipeline completed successfully!$(NC)"

all: clean install ci ## Clean, install, and run full CI pipeline
	@echo "$(GREEN)🎉 Full pipeline completed successfully!$(NC)"

# Development helpers
check: ## Check if Flutter is properly installed
	@echo "$(BLUE)Checking Flutter installation...$(NC)"
	flutter doctor -v

upgrade: ## Upgrade Flutter and dependencies
	@echo "$(BLUE)Upgrading Flutter and dependencies...$(NC)"
	flutter upgrade
	flutter pub upgrade
	@echo "$(GREEN)Upgrade completed!$(NC)"

# Git helpers
pre-commit: ## Run pre-commit checks (format + lint)
	@echo "$(BLUE)Running pre-commit checks...$(NC)"
	@$(MAKE) format
	@$(MAKE) lint
	@echo "$(GREEN)Pre-commit checks completed!$(NC)"

pre-push: ci ## Run pre-push checks (full CI)
	@echo "$(GREEN)✅ Pre-push checks completed!$(NC)"
