# changelog-template-action

Generate changelogs from templates with reference to git history, tags and merged pull requests

## Usage

* template file (release-note-with-body.md.j2)

```markdown
[Compare {{ from_revision }} with {{ to_revision }}]({{ env('GITHUB_SERVER_URL') }}/{{ inputs.owner }}/{{ inputs.repo }}/compare/{{ from_revision }}...{{ to_revision }})

## Changes

{% for pull_request in pull_requests %}
* [{{ pull_request. title }}]({{ pull_request.url }}) - {{ pull_request.author.login }} {{ pull_request.mergedAt }}  
{%- if pull_request.body | length > 0 -%}
    <details><summary>details</summary>
    
    {{ pull_request.body | indent(4) }}
    </details>
{%- endif %}
{%- endfor %}
```

* workflow

```yaml
permissions:
  contents: read
  pull-requests: read

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: changelog
        id: changelog
        uses: srz-zumix/changelog-template-action@v2
        with:
          template_file: release-note-with-body.md.j2
          output_file: changelog.md
          from: "v1.1.0"
          to: "v1.2.0"
```

## Example

### Update Release Notes on published

```yaml
name: UpdateReleaseNotes
on:
  release:
    types:
      - published

permissions:
  contents: write
  pull-requests: read

env:
  GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

jobs:
  update-release-notes:
    runs-on: ubuntu-latest
    steps:
      - name: changelog
        id: changelog
        uses: srz-zumix/changelog-template-action@v2
        with:
          template_file: testdata/release-note-with-body.md.j2
          output_file: changelog.md
      - name: update
        run: |
          gh release edit ${{ github.event.release.tag_name}} -F changelog.md
```
