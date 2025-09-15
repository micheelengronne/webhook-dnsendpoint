{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "dnsendpoint-webhook.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "dnsendpoint-webhook.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "dnsendpoint-webhook.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "dnsendpoint-webhook.selfSignedIssuer" -}}
{{ printf "%s-selfsign" (include "dnsendpoint-webhook.fullname" .) }}
{{- end -}}

{{- define "dnsendpoint-webhook.rootCAIssuer" -}}
{{ printf "%s-ca" (include "dnsendpoint-webhook.fullname" .) }}
{{- end -}}

{{- define "dnsendpoint-webhook.rootCACertificate" -}}
{{ printf "%s-ca" (include "dnsendpoint-webhook.fullname" .) }}
{{- end -}}

{{- define "dnsendpoint-webhook.servingCertificate" -}}
{{ printf "%s-webhook-tls" (include "dnsendpoint-webhook.fullname" .) }}
{{- end -}}
