@'
name-template: 'v$RESOLVED_VERSION 🌈'
tag-template: 'v$RESOLVED_VERSION'
categories:
  - title: '🚀 Features'
    labels:
      - 'feature'
      - 'enhancement'
      - 'change'
  - title: '🐛 Bug Fixes'
    labels:
      - 'fix'
      - 'bug'
  - title: '🖊️ Refactors'
    labels:
      - 'refactor'
  - title: '👗 Style'
    labels:
      - 'style'
  - title: '📝 Documentation'
    labels:
      - 'docs'
      - 'documentation'
  - title: '🧰 Maintenance'
    label: 'chore'
change-template: '- $TITLE @$AUTHOR (#$NUMBER)'
version-resolver:
  major:
    labels:
      - 'breaking'
  minor:
    labels:
      - 'feature'
      - 'enhancement'
      - 'change'
      - 'refactor'
  patch:
    labels:
      - 'fix'
      - 'bug'
      - 'style'
      - 'docs'
      - 'documentation'
      - 'chore'
  default: patch
sort-by: title
template: |
  ## Changes

  $CHANGES

'@
