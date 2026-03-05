# Makefile for app_cemdo

# Default flavor
FLAVOR ?= development

.PHONY: build-android-prod
build-android-prod:
	flutter build apk --flavor production --dart-define=FLAVOR=production

.PHONY: build-bundle-prod
build-bundle-prod:
	flutter build appbundle --flavor production --dart-define=FLAVOR=production

.PHONY: run-prod
run-prod:
	flutter run --flavor production --dart-define=FLAVOR=production

.PHONY: build-android-dev
build-android-dev:
	flutter build apk --flavor development --dart-define=FLAVOR=development

.PHONY: run-dev
run-dev:
	flutter run --flavor development --dart-define=FLAVOR=development
