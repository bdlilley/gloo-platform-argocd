{{ define "app.defaultSyncPolicy" }}
automated:
  prune: true
  selfHeal: true
syncOptions:
- CreateNamespace=true
{{- end }}

{{- define "app.syncPolicy" }}
{{- $def := include "app.defaultSyncPolicy" . }}
{{- if (.).syncPolicy }}
{{-  toYaml (mergeOverwrite (deepCopy (fromYaml $def)) .syncPolicy ) | nindent 4}}
{{- else }}
{{- $def | nindent 4 }}
{{- end }}
{{- end }}

{{- define "app.wave" }}
{{- if (.).wave }}
{{- .wave | quote }}
{{- else }}
{{- "100" | quote }}
{{- end }}
{{- end }}