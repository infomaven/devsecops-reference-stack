{{/*
Name helpers, standard chart boilerplate.
*/}}
{{- define "paymentsvc.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "paymentsvc.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "paymentsvc.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "paymentsvc.labels" -}}
app.kubernetes.io/name: {{ include "paymentsvc.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: payments
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "paymentsvc.selectorLabels" -}}
app.kubernetes.io/name: {{ include "paymentsvc.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Guardrail: fail the render rather than ship a floating tag. The Rego policy
catches this too, so a reviewer sees it fail in CI even if someone renders
the chart with --set.
*/}}
{{- define "paymentsvc.image" -}}
{{- if or (eq .Values.image.tag "latest") (empty .Values.image.tag) -}}
{{- fail "image.tag must be an explicit version, not latest or empty" -}}
{{- end -}}
{{- printf "%s:%s" .Values.image.repository .Values.image.tag -}}
{{- end -}}
